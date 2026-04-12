import BabyTrackerDomain
import Foundation
import Testing

// MARK: - Local stubs (Domain protocol only, no Persistence dependency)

@MainActor
private final class StubMembershipRepository: MembershipRepository {
    var membershipsByChildID: [UUID: [Membership]] = [:]

    func loadMemberships(for childID: UUID) throws -> [Membership] {
        membershipsByChildID[childID] ?? []
    }

    func saveMembership(_ membership: Membership) throws {
        membershipsByChildID[membership.childID, default: []].append(membership)
    }
}

@MainActor
private final class StubEventRepository: EventRepository {
    var eventsByChildID: [UUID: [BabyEvent]] = [:]
    var activeSleepByChildID: [UUID: SleepEvent] = [:]

    func saveEvent(_ event: BabyEvent) throws {
        eventsByChildID[event.metadata.childID, default: []].append(event)
    }

    func loadEvent(id: UUID) throws -> BabyEvent? { nil }

    func loadTimeline(for childID: UUID, includingDeleted: Bool) throws -> [BabyEvent] {
        eventsByChildID[childID] ?? []
    }

    func loadEvents(for childID: UUID, on day: Date, calendar: Calendar, includingDeleted: Bool) throws -> [BabyEvent] {
        eventsByChildID[childID] ?? []
    }

    func loadActiveSleepEvent(for childID: UUID) throws -> SleepEvent? {
        activeSleepByChildID[childID]
    }

    func softDeleteEvent(id: UUID, deletedAt: Date, deletedBy: UUID) throws {}
}

@MainActor
private final class StubUserIdentityRepository: UserIdentityRepository {
    var usersByID: [UUID: UserIdentity] = [:]

    func loadLocalUser() throws -> UserIdentity? { nil }
    func saveLocalUser(_ user: UserIdentity) throws {}
    func loadUsers(for userIDs: [UUID]) throws -> [UserIdentity] {
        userIDs.compactMap { usersByID[$0] }
    }
    func saveUser(_ user: UserIdentity) throws { usersByID[user.id] = user }
    func removeLegacyPlaceholderCaregivers() throws {}
    func resetAllData() throws {}
}

// MARK: - LoadChildSummariesUseCase Tests

@MainActor
struct LoadChildSummariesUseCaseTests {
    let userID = UUID()
    let membershipRepo = StubMembershipRepository()

    private func makeChild(createdAt: Date = .now) throws -> Child {
        try Child(name: "Test Child", createdAt: createdAt, createdBy: userID)
    }

    @Test
    func childWithActiveMembershipIsIncluded() throws {
        let child = try makeChild()
        membershipRepo.membershipsByChildID[child.id] = [
            Membership.owner(childID: child.id, userID: userID)
        ]

        let result = try LoadChildSummariesUseCase(membershipRepository: membershipRepo)
            .execute(.init(children: [child], userID: userID))

        #expect(result.count == 1)
        #expect(result[0].child.id == child.id)
        #expect(result[0].membership.userID == userID)
    }

    @Test
    func childWithNoMembershipsIsSkipped() throws {
        let child = try makeChild()
        // No memberships stored for this child

        let result = try LoadChildSummariesUseCase(membershipRepository: membershipRepo)
            .execute(.init(children: [child], userID: userID))

        #expect(result.isEmpty)
    }

    @Test
    func childWithRemovedMembershipIsSkipped() throws {
        let child = try makeChild()
        let invited = Membership.invitedCaregiver(childID: child.id, userID: userID)
        let removed = try invited.removed()
        membershipRepo.membershipsByChildID[child.id] = [removed]

        let result = try LoadChildSummariesUseCase(membershipRepository: membershipRepo)
            .execute(.init(children: [child], userID: userID))

        #expect(result.isEmpty)
    }

    @Test
    func childWithInvitedMembershipIsSkipped() throws {
        let child = try makeChild()
        membershipRepo.membershipsByChildID[child.id] = [
            Membership.invitedCaregiver(childID: child.id, userID: userID)
        ]

        let result = try LoadChildSummariesUseCase(membershipRepository: membershipRepo)
            .execute(.init(children: [child], userID: userID))

        #expect(result.isEmpty)
    }

    @Test
    func onlyChildrenWithActiveMembershipForLocalUserAreIncluded() throws {
        let ownedChild = try makeChild()
        let otherUserID = UUID()
        let sharedChild = try Child(name: "Shared", createdBy: otherUserID)

        membershipRepo.membershipsByChildID[ownedChild.id] = [
            Membership.owner(childID: ownedChild.id, userID: userID)
        ]
        membershipRepo.membershipsByChildID[sharedChild.id] = [
            Membership.owner(childID: sharedChild.id, userID: otherUserID)
            // local user has no membership for sharedChild
        ]

        let result = try LoadChildSummariesUseCase(membershipRepository: membershipRepo)
            .execute(.init(children: [ownedChild, sharedChild], userID: userID))

        #expect(result.count == 1)
        #expect(result[0].child.id == ownedChild.id)
    }

    @Test
    func resultsAreSortedByCreatedAtAscending() throws {
        let now = Date()
        let older = try Child(name: "Older", createdAt: now.addingTimeInterval(-3600), createdBy: userID)
        let newer = try Child(name: "Newer", createdAt: now, createdBy: userID)

        for child in [newer, older] {
            membershipRepo.membershipsByChildID[child.id] = [
                Membership.owner(childID: child.id, userID: userID)
            ]
        }

        let result = try LoadChildSummariesUseCase(membershipRepository: membershipRepo)
            .execute(.init(children: [newer, older], userID: userID))

        #expect(result.map(\.child.id) == [older.id, newer.id])
    }

    @Test
    func emptyChildListReturnsEmptySummaries() throws {
        let result = try LoadChildSummariesUseCase(membershipRepository: membershipRepo)
            .execute(.init(children: [], userID: userID))

        #expect(result.isEmpty)
    }
}

// MARK: - ResolveChildWorkspaceUseCase Tests

@MainActor
struct ResolveChildWorkspaceUseCaseTests {
    let userID = UUID()
    let useCase = ResolveChildWorkspaceUseCase()

    private func makeSummary(childID: UUID = UUID()) throws -> ChildSummary {
        let child = try Child(name: "Child", createdBy: userID)
        let membership = Membership.owner(childID: child.id, userID: userID)
        return ChildSummary(child: child, membership: membership)
    }

    @Test
    func noActiveChildrenResolvesToNoActiveChildren() throws {
        let result = useCase.execute(.init(activeChildren: [], selectedChildID: nil))
        #expect(result == .noActiveChildren)
    }

    @Test
    func noActiveChildrenIgnoresSelectedID() throws {
        let result = useCase.execute(.init(activeChildren: [], selectedChildID: UUID()))
        #expect(result == .noActiveChildren)
    }

    @Test
    func singleChildResolvesRegardlessOfSelectedID() throws {
        let summary = try makeSummary()

        let resultWithNilID = useCase.execute(.init(activeChildren: [summary], selectedChildID: nil))
        let resultWithWrongID = useCase.execute(.init(activeChildren: [summary], selectedChildID: UUID()))
        let resultWithMatchingID = useCase.execute(.init(activeChildren: [summary], selectedChildID: summary.child.id))

        #expect(resultWithNilID == .resolved(summary))
        #expect(resultWithWrongID == .resolved(summary))
        #expect(resultWithMatchingID == .resolved(summary))
    }

    @Test
    func multipleChildrenWithMatchingSelectedIDResolvesCorrectChild() throws {
        let first = try makeSummary()
        let second = try makeSummary()

        let result = useCase.execute(.init(activeChildren: [first, second], selectedChildID: second.child.id))

        #expect(result == .resolved(second))
    }

    @Test
    func multipleChildrenWithNoSelectedIDNeedsChildSelection() throws {
        let first = try makeSummary()
        let second = try makeSummary()

        let result = useCase.execute(.init(activeChildren: [first, second], selectedChildID: nil))

        #expect(result == .needsChildSelection)
    }

    @Test
    func multipleChildrenWithUnknownSelectedIDNeedsChildSelection() throws {
        let first = try makeSummary()
        let second = try makeSummary()

        let result = useCase.execute(.init(activeChildren: [first, second], selectedChildID: UUID()))

        #expect(result == .needsChildSelection)
    }
}

// MARK: - LoadChildWorkspaceDataUseCase Tests

@MainActor
struct LoadChildWorkspaceDataUseCaseTests {
    let userID = UUID()
    let childID = UUID()
    let eventRepo = StubEventRepository()
    let membershipRepo = StubMembershipRepository()
    let userIdentityRepo = StubUserIdentityRepository()

    private func makeUseCase() -> LoadChildWorkspaceDataUseCase {
        LoadChildWorkspaceDataUseCase(
            eventRepository: eventRepo,
            membershipRepository: membershipRepo,
            userIdentityRepository: userIdentityRepo
        )
    }

    @Test
    func loadsEventsForChild() throws {
        membershipRepo.membershipsByChildID[childID] = [
            Membership.owner(childID: childID, userID: userID)
        ]
        let event = try BottleFeedEvent(
            metadata: EventMetadata(childID: childID, occurredAt: .now, createdBy: userID),
            amountMilliliters: 120
        )
        eventRepo.eventsByChildID[childID] = [.bottleFeed(event)]

        let output = try makeUseCase().execute(.init(childID: childID, localUserID: userID))

        #expect(output.events.count == 1)
        #expect(output.events[0].id == event.id)
    }

    @Test
    func loadsActiveSleepForChild() throws {
        membershipRepo.membershipsByChildID[childID] = [
            Membership.owner(childID: childID, userID: userID)
        ]
        let sleep = try SleepEvent(
            metadata: EventMetadata(childID: childID, occurredAt: .now, createdBy: userID),
            startedAt: .now
        )
        eventRepo.activeSleepByChildID[childID] = sleep

        let output = try makeUseCase().execute(.init(childID: childID, localUserID: userID))

        #expect(output.activeSleep?.id == sleep.id)
    }

    @Test
    func noActiveSleepReturnsNil() throws {
        membershipRepo.membershipsByChildID[childID] = [
            Membership.owner(childID: childID, userID: userID)
        ]

        let output = try makeUseCase().execute(.init(childID: childID, localUserID: userID))

        #expect(output.activeSleep == nil)
    }

    @Test
    func resolvedMembershipBelongsToLocalUser() throws {
        let ownerMembership = Membership.owner(childID: childID, userID: userID)
        let otherUser = UUID()
        let caregiverMembership = Membership(
            childID: childID,
            userID: otherUser,
            role: .caregiver,
            status: .active,
            invitedAt: .now,
            acceptedAt: .now
        )
        membershipRepo.membershipsByChildID[childID] = [ownerMembership, caregiverMembership]

        let output = try makeUseCase().execute(.init(childID: childID, localUserID: userID))

        #expect(output.currentMembership.userID == userID)
        #expect(output.currentMembership.role == .owner)
    }

    @Test
    func allMembershipsAreReturnedInOutput() throws {
        let owner = Membership.owner(childID: childID, userID: userID)
        let caregiver = Membership(
            childID: childID,
            userID: UUID(),
            role: .caregiver,
            status: .active,
            invitedAt: .now,
            acceptedAt: .now
        )
        membershipRepo.membershipsByChildID[childID] = [owner, caregiver]

        let output = try makeUseCase().execute(.init(childID: childID, localUserID: userID))

        #expect(output.memberships.count == 2)
    }

    @Test
    func membershipUsersAreLoadedForAllMemberships() throws {
        let otherUserID = UUID()
        membershipRepo.membershipsByChildID[childID] = [
            Membership.owner(childID: childID, userID: userID),
            Membership(childID: childID, userID: otherUserID, role: .caregiver, status: .active, invitedAt: .now, acceptedAt: .now)
        ]
        let otherUser = try UserIdentity(id: otherUserID, displayName: "Caregiver")
        userIdentityRepo.usersByID[otherUserID] = otherUser

        let output = try makeUseCase().execute(.init(childID: childID, localUserID: userID))

        #expect(output.membershipUsers.contains(where: { $0.id == otherUserID }))
    }

    @Test
    func throwsWhenLocalUserHasNoMembership() throws {
        membershipRepo.membershipsByChildID[childID] = []

        #expect(throws: ChildProfileValidationError.invalidMembershipTransition(from: .removed, to: .active)) {
            try makeUseCase().execute(.init(childID: childID, localUserID: userID))
        }
    }

    @Test
    func throwsWhenLocalUserMembershipIsRemoved() throws {
        let invited = Membership.invitedCaregiver(childID: childID, userID: userID)
        let removed = try invited.removed()
        membershipRepo.membershipsByChildID[childID] = [removed]

        #expect(throws: ChildProfileValidationError.invalidMembershipTransition(from: .removed, to: .active)) {
            try makeUseCase().execute(.init(childID: childID, localUserID: userID))
        }
    }
}
