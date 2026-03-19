import BabyTrackerDomain
import BabyTrackerPersistence
import Foundation
import Testing

@MainActor
struct ChildProfilePersistenceTests {
    @Test
    func savesAndReloadsLocalUserIdentity() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let user = try UserIdentity(displayName: "Alex Parent")

        try harness.repository.saveLocalUser(user)

        let loadedUser = try #require(try harness.repository.loadLocalUser())

        #expect(loadedUser == user)
    }

    @Test
    func savesChildAndOwnerMembershipAsActiveProfile() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let owner = try UserIdentity(displayName: "Alex Parent")
        let child = try Child(name: "Poppy", createdBy: owner.id)

        try harness.repository.saveLocalUser(owner)
        try harness.repository.saveChild(child)
        try harness.repository.saveMembership(.owner(childID: child.id, userID: owner.id, createdAt: child.createdAt))

        let activeChildren = try harness.repository.loadActiveChildren(for: owner.id)
        let memberships = try harness.repository.loadMemberships(for: child.id)

        #expect(activeChildren == [child])
        #expect(memberships.count == 1)
        #expect(memberships.first?.role == .owner)
        #expect(memberships.first?.status == .active)
    }

    @Test
    func persistsMembershipLifecycleAndArchiveState() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let owner = try UserIdentity(displayName: "Owner")
        let caregiver = try UserIdentity(displayName: "Caregiver")
        var child = try Child(name: "Robin", createdBy: owner.id)
        let ownerMembership = Membership.owner(childID: child.id, userID: owner.id, createdAt: child.createdAt)
        let invitedMembership = Membership.invitedCaregiver(childID: child.id, userID: caregiver.id)

        try harness.repository.saveLocalUser(owner)
        try harness.repository.saveUser(caregiver)
        try harness.repository.saveChild(child)
        try harness.repository.saveMembership(ownerMembership)
        try harness.repository.saveMembership(invitedMembership)

        let activeMembership = try invitedMembership.activated()
        try harness.repository.saveMembership(activeMembership)
        try harness.repository.saveMembership(try activeMembership.removed())

        child.isArchived = true
        try harness.repository.saveChild(child)

        let activeChildren = try harness.repository.loadActiveChildren(for: owner.id)
        let archivedChildren = try harness.repository.loadArchivedChildren(for: owner.id)
        let memberships = try harness.repository.loadMemberships(for: child.id)

        #expect(activeChildren.isEmpty)
        #expect(archivedChildren == [child])
        #expect(memberships.map(\.status) == [.active, .removed])

        child.isArchived = false
        try harness.repository.saveChild(child)

        let restoredChildren = try harness.repository.loadActiveChildren(for: owner.id)

        #expect(restoredChildren == [child])
    }

    @Test
    func savesSelectedChildIdentifier() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let childID = UUID()

        harness.repository.saveSelectedChildID(childID)

        #expect(harness.repository.loadSelectedChildID() == childID)
    }

    @Test
    func linksLocalUserToCanonicalCloudKitIdentity() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let localOwner = try UserIdentity(displayName: "Alex Parent")
        let canonicalOwner = try UserIdentity(
            displayName: "Cloud Alex",
            cloudKitUserRecordName: "owner.record"
        )
        let child = try Child(name: "Poppy", createdBy: localOwner.id)

        try harness.repository.saveUser(canonicalOwner)
        try harness.repository.saveLocalUser(localOwner)
        try harness.repository.saveChild(child)
        try harness.repository.saveMembership(
            .owner(
                childID: child.id,
                userID: localOwner.id,
                createdAt: child.createdAt
            )
        )

        let linkedUser = try #require(
            try harness.repository.linkLocalUser(
                toCloudKitUserRecordName: "owner.record"
            )
        )
        let memberships = try harness.repository.loadMemberships(for: child.id)
        let activeChildren = try harness.repository.loadActiveChildren(for: canonicalOwner.id)

        #expect(linkedUser.id == canonicalOwner.id)
        #expect(linkedUser.displayName == localOwner.displayName)
        #expect(memberships.map(\.userID) == [canonicalOwner.id])
        #expect(activeChildren.count == 1)
        #expect(activeChildren.first?.id == child.id)
        #expect(activeChildren.first?.createdBy == canonicalOwner.id)
    }

    @Test
    func removesLegacyPlaceholderCaregiversWithoutCloudKitLinkage() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let owner = try UserIdentity(displayName: "Alex Parent")
        let placeholderCaregiver = try UserIdentity(displayName: "Legacy Helper")
        let cloudLinkedCaregiver = try UserIdentity(
            displayName: "Cloud Helper",
            cloudKitUserRecordName: "helper.record"
        )
        let child = try Child(name: "Robin", createdBy: owner.id)

        try harness.repository.saveLocalUser(owner)
        try harness.repository.saveUser(placeholderCaregiver)
        try harness.repository.saveUser(cloudLinkedCaregiver)
        try harness.repository.saveChild(child)
        try harness.repository.saveMembership(
            .owner(
                childID: child.id,
                userID: owner.id,
                createdAt: child.createdAt
            )
        )
        try harness.repository.saveMembership(
            Membership(
                childID: child.id,
                userID: placeholderCaregiver.id,
                role: .caregiver,
                status: .active,
                invitedAt: child.createdAt,
                acceptedAt: child.createdAt
            )
        )
        try harness.repository.saveMembership(
            Membership(
                childID: child.id,
                userID: cloudLinkedCaregiver.id,
                role: .caregiver,
                status: .active,
                invitedAt: child.createdAt,
                acceptedAt: child.createdAt
            )
        )

        try harness.repository.removeLegacyPlaceholderCaregivers()

        let memberships = try harness.repository.loadMemberships(for: child.id)
        let remainingUsers = try harness.repository.loadUsers(
            for: [owner.id, placeholderCaregiver.id, cloudLinkedCaregiver.id]
        )

        #expect(memberships.count == 2)
        #expect(!memberships.contains(where: { $0.userID == placeholderCaregiver.id }))
        #expect(remainingUsers.contains(where: { $0.id == owner.id }))
        #expect(!remainingUsers.contains(where: { $0.id == placeholderCaregiver.id }))
        #expect(remainingUsers.contains(where: { $0.id == cloudLinkedCaregiver.id }))
    }
}

extension ChildProfilePersistenceTests {
    @MainActor
    private struct RepositoryHarness {
        let suiteName = "BabyTrackerTests.\(UUID().uuidString)"
        let userDefaults: UserDefaults
        let repository: SwiftDataChildProfileRepository

        init() throws {
            let userDefaults = UserDefaults(suiteName: suiteName)!
            userDefaults.removePersistentDomain(forName: suiteName)

            self.userDefaults = userDefaults
            self.repository = try SwiftDataChildProfileRepository(
                isStoredInMemoryOnly: true,
                userDefaults: userDefaults
            )
        }

        func cleanUp() {
            userDefaults.removePersistentDomain(forName: suiteName)
        }
    }
}
