import BabyTrackerDomain
import BabyTrackerPersistence
import BabyTrackerSync
import Foundation
import Observation

@MainActor
@Observable
public final class AppModel {
    public private(set) var route: AppRoute = .loading
    public private(set) var localUser: UserIdentity?
    public private(set) var activeChildren: [ChildSummary] = []
    public private(set) var archivedChildren: [ChildSummary] = []
    public private(set) var profile: ChildProfileScreenState?
    public private(set) var errorMessage: String?
    public var shareSheetState: ShareSheetState?

    private let repository: ChildProfileRepository
    private let eventRepository: EventRepository
    private let syncEngine: CloudKitSyncEngine

    public init(
        repository: ChildProfileRepository,
        eventRepository: EventRepository,
        syncEngine: CloudKitSyncEngine
    ) {
        self.repository = repository
        self.eventRepository = eventRepository
        self.syncEngine = syncEngine
    }

    public func load(performLaunchSync: Bool = true) {
        refresh(selecting: nil)

        guard performLaunchSync else {
            return
        }

        Task { @MainActor in
            _ = await syncEngine.prepareForLaunch()
            refresh(selecting: repository.loadSelectedChildID())
        }
    }

    public func dismissError() {
        errorMessage = nil
    }

    public func dismissShareSheet() {
        shareSheetState = nil
    }

    public func refreshAfterShareSheet() {
        Task { @MainActor in
            _ = await syncEngine.refreshForeground()
            refresh(selecting: repository.loadSelectedChildID())
        }
    }

    public func createLocalUser(displayName: String) {
        perform {
            let user = try UserIdentity(displayName: displayName)
            try repository.saveLocalUser(user)
        }
    }

    public func createChild(name: String, birthDate: Date?) {
        perform {
            guard let localUser else { return }

            let child = try Child(
                name: name,
                birthDate: birthDate,
                createdBy: localUser.id
            )
            let ownerMembership = Membership.owner(
                childID: child.id,
                userID: localUser.id,
                createdAt: child.createdAt
            )

            try repository.saveChild(child)
            try repository.saveMembership(ownerMembership)
            repository.saveSelectedChildID(child.id)
        }
    }

    public func updateCurrentChild(name: String, birthDate: Date?) {
        perform {
            guard let profile else { return }
            guard profile.canEditChild else {
                throw ChildProfileValidationError.insufficientPermissions
            }

            let updatedChild = try profile.child.updating(name: name, birthDate: birthDate)
            try repository.saveChild(updatedChild)
        }
    }

    public func archiveCurrentChild() {
        perform {
            guard let profile else { return }
            guard profile.canArchiveChild else {
                throw ChildProfileValidationError.insufficientPermissions
            }

            var archivedChild = profile.child
            archivedChild.isArchived = true
            try repository.saveChild(archivedChild)

            if repository.loadSelectedChildID() == archivedChild.id {
                repository.saveSelectedChildID(nil)
            }
        }
    }

    public func restoreChild(id: UUID) {
        perform {
            guard var restoredChild = try repository.loadChild(id: id) else { return }
            restoredChild.isArchived = false
            try repository.saveChild(restoredChild)
            repository.saveSelectedChildID(id)
        }
    }

    public func selectChild(id: UUID) {
        repository.saveSelectedChildID(id)
        refresh(selecting: id)
    }

    public func showChildPicker() {
        guard activeChildren.count > 1 else {
            return
        }

        route = .childPicker
    }

    public func presentShareSheet() {
        guard let profile, profile.canShareChild else {
            return
        }

        Task { @MainActor in
            do {
                let presentation = try await syncEngine.prepareShare(
                    for: profile.child.id
                )
                shareSheetState = ShareSheetState(presentation: presentation)
                refresh(selecting: repository.loadSelectedChildID())
            } catch {
                errorMessage = resolveErrorMessage(for: error)
            }
        }
    }

    public func removeCaregiver(membershipID: UUID) {
        guard let profile else {
            return
        }

        perform {
            guard profile.canManageSharing else {
                throw ChildProfileValidationError.insufficientPermissions
            }

            let candidateMemberships = profile.activeCaregivers.map(\.membership) +
                profile.removedCaregivers.map(\.membership) +
                [profile.owner.membership]

            guard let membership = candidateMemberships.first(where: { $0.id == membershipID }) else {
                return
            }

            try MembershipValidator.validateRemoval(
                of: membership,
                within: candidateMemberships
            )
            let removedMembership = try membership.removed()
            try repository.saveMembership(removedMembership)

            Task { @MainActor in
                try? await syncEngine.removeParticipant(membership: removedMembership)
                refresh(selecting: repository.loadSelectedChildID())
            }
        }
    }

    @discardableResult
    public func logBreastFeed(
        durationMinutes: Int,
        endTime: Date,
        side: BreastSide?
    ) -> Bool {
        perform {
            guard let profile else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let localUser else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard profile.canLogFeeds else {
                throw ChildProfileValidationError.insufficientPermissions
            }

            let startedAt = endTime.addingTimeInterval(TimeInterval(durationMinutes * -60))
            let event = try BreastFeedEvent(
                metadata: EventMetadata(
                    childID: profile.child.id,
                    occurredAt: endTime,
                    createdAt: .now,
                    createdBy: localUser.id
                ),
                side: side,
                startedAt: startedAt,
                endedAt: endTime
            )

            try eventRepository.saveEvent(.breastFeed(event))
        }
    }

    @discardableResult
    public func logBottleFeed(
        amountMilliliters: Int,
        occurredAt: Date,
        milkType: MilkType?
    ) -> Bool {
        perform {
            guard let profile else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let localUser else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard profile.canLogFeeds else {
                throw ChildProfileValidationError.insufficientPermissions
            }

            let event = try BottleFeedEvent(
                metadata: EventMetadata(
                    childID: profile.child.id,
                    occurredAt: occurredAt,
                    createdAt: .now,
                    createdBy: localUser.id
                ),
                amountMilliliters: amountMilliliters,
                milkType: milkType
            )

            try eventRepository.saveEvent(.bottleFeed(event))
        }
    }

    @discardableResult
    private func perform(_ operation: () throws -> Void) -> Bool {
        do {
            try operation()
            refresh(selecting: repository.loadSelectedChildID())
            Task { @MainActor in
                _ = await syncEngine.refreshAfterLocalWrite()
                refresh(selecting: repository.loadSelectedChildID())
            }
            return true
        } catch {
            errorMessage = resolveErrorMessage(for: error)
            refresh(selecting: repository.loadSelectedChildID())
            return false
        }
    }

    private func refresh(selecting selectedChildID: UUID?) {
        do {
            localUser = try repository.loadLocalUser()

            guard let localUser else {
                route = .identityOnboarding
                activeChildren = []
                archivedChildren = []
                profile = nil
                return
            }

            activeChildren = try loadChildSummaries(
                children: repository.loadActiveChildren(for: localUser.id),
                userID: localUser.id
            )
            archivedChildren = try loadChildSummaries(
                children: repository.loadArchivedChildren(for: localUser.id),
                userID: localUser.id
            )

            guard !activeChildren.isEmpty else {
                route = .childCreation
                profile = nil
                return
            }

            let effectiveSelectedChildID = selectedChildID ?? repository.loadSelectedChildID()
            let selectedSummary = activeChildren.first(where: { summary in
                summary.child.id == effectiveSelectedChildID
            })

            if activeChildren.count > 1 && selectedSummary == nil {
                route = .childPicker
                profile = nil
                return
            }

            let currentSummary = selectedSummary ?? activeChildren[0]
            repository.saveSelectedChildID(currentSummary.child.id)
            profile = try makeProfile(
                child: currentSummary.child,
                localUser: localUser
            )
            route = .childProfile
        } catch {
            errorMessage = resolveErrorMessage(for: error)
            route = .identityOnboarding
        }
    }

    private func loadChildSummaries(
        children: [Child],
        userID: UUID
    ) throws -> [ChildSummary] {
        var summaries: [ChildSummary] = []

        for child in children {
            let memberships = try repository.loadMemberships(for: child.id)
            guard let membership = memberships.first(where: { membership in
                membership.userID == userID && membership.status == .active
            }) else {
                continue
            }

            summaries.append(ChildSummary(child: child, membership: membership))
        }

        return summaries.sorted { left, right in
            left.child.createdAt < right.child.createdAt
        }
    }

    private func makeProfile(
        child: Child,
        localUser: UserIdentity
    ) throws -> ChildProfileScreenState {
        let memberships = try repository.loadMemberships(for: child.id)
        let userIDs = memberships.map(\.userID)
        let users = try repository.loadUsers(for: userIDs)
        let usersByID = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })

        guard let currentMembership = memberships.first(where: { membership in
            membership.userID == localUser.id && membership.status == .active
        }) else {
            throw ChildProfileValidationError.invalidMembershipTransition(
                from: .removed,
                to: .active
            )
        }

        let pairs = memberships.compactMap { membership -> CaregiverMembershipViewState? in
            guard let user = usersByID[membership.userID] else {
                return nil
            }

            return CaregiverMembershipViewState(user: user, membership: membership)
        }

        guard let owner = pairs.first(where: { pair in
            pair.membership.role == .owner && pair.membership.status == .active
        }) else {
            throw ChildProfileValidationError.missingOwner
        }

        let activeCaregivers = pairs.filter { pair in
            pair.membership.role == .caregiver && pair.membership.status == .active
        }
        let removedCaregivers = pairs.filter { pair in
            pair.membership.status == .removed
        }

        let pendingShareInvites = syncEngine.pendingInvites(for: child.id).map { invite in
            PendingShareInviteViewState(
                id: invite.id,
                displayName: invite.displayName,
                statusLabel: invite.acceptanceStatus == .pending ? "Pending invitation" : "Invited"
            )
        }
        let feedingSummary = try makeFeedingSummary(for: child.id)
        let canLogFeeds = ChildAccessPolicy.canPerform(.logEvent, membership: currentMembership)

        return ChildProfileScreenState(
            child: child,
            localUser: localUser,
            currentMembership: currentMembership,
            owner: owner,
            activeCaregivers: activeCaregivers,
            pendingShareInvites: pendingShareInvites,
            removedCaregivers: removedCaregivers,
            canSwitchChildren: activeChildren.count > 1,
            canLogFeeds: canLogFeeds,
            feedingSummary: feedingSummary,
            syncBannerState: makeSyncBannerState(from: syncEngine.statusSummary),
            canShareChild: ChildAccessPolicy.canPerform(.inviteCaregiver, membership: currentMembership) &&
                syncEngine.statusSummary.state != .failed
        )
    }

    private func makeFeedingSummary(
        for childID: UUID
    ) throws -> FeedingSummaryViewState? {
        let events = try eventRepository.loadTimeline(for: childID, includingDeleted: false)

        guard let summary = FeedSummaryCalculator.makeSummary(from: events) else {
            return nil
        }

        return FeedingSummaryViewState(summary: summary)
    }

    private func makeSyncBannerState(
        from summary: SyncStatusSummary
    ) -> SyncBannerState? {
        switch summary.state {
        case .upToDate:
            return nil
        case .syncing:
            return .syncing
        case .pendingSync:
            return .pendingSync("Changes saved locally. Sync will resume automatically.")
        case .failed:
            guard let description = summary.lastErrorDescription else {
                return .lastSyncFailed("Last sync failed. Local data is still available.")
            }

            if description.localizedCaseInsensitiveContains("sign in to iCloud") ||
                description.localizedCaseInsensitiveContains("unavailable") {
                return .syncUnavailable(description)
            }

            return .lastSyncFailed(description)
        }
    }

    private func resolveErrorMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }

        return "Something went wrong. Please try again."
    }
}
