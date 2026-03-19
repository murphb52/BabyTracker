import BabyTrackerDomain
import BabyTrackerPersistence
import Foundation
import Observation

@MainActor
@Observable
public final class Stage1AppModel {
    public private(set) var route: Stage1Route = .loading
    public private(set) var localUser: UserIdentity?
    public private(set) var activeChildren: [ChildSummary] = []
    public private(set) var archivedChildren: [ChildSummary] = []
    public private(set) var profile: ChildProfileScreenState?
    public private(set) var errorMessage: String?

    private let repository: ChildProfileRepository

    public init(repository: ChildProfileRepository) {
        self.repository = repository
    }

    public func load() {
        refresh(selecting: nil)
    }

    public func dismissError() {
        errorMessage = nil
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

    public func inviteCaregiver(displayName: String) {
        perform {
            guard let profile else { return }
            guard profile.canManageSharing else {
                throw ChildProfileValidationError.insufficientPermissions
            }

            let caregiver = try UserIdentity(displayName: displayName)
            let membership = Membership.invitedCaregiver(
                childID: profile.child.id,
                userID: caregiver.id
            )

            try repository.saveUser(caregiver)
            try repository.saveMembership(membership)
        }
    }

    public func activateCaregiver(membershipID: UUID) {
        perform {
            guard let profile else { return }
            guard profile.canManageSharing else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let membership = profile.invitedCaregivers.first(where: { $0.membership.id == membershipID })?.membership else {
                return
            }

            try repository.saveMembership(try membership.activated())
        }
    }

    public func removeCaregiver(membershipID: UUID) {
        perform {
            guard let profile else { return }
            guard profile.canManageSharing else {
                throw ChildProfileValidationError.insufficientPermissions
            }

            let candidateMemberships = profile.activeCaregivers.map(\.membership) +
                profile.invitedCaregivers.map(\.membership) +
                profile.removedCaregivers.map(\.membership) +
                [profile.owner.membership]

            guard let membership = candidateMemberships.first(where: { $0.id == membershipID }) else {
                return
            }

            try MembershipValidator.validateRemoval(
                of: membership,
                within: candidateMemberships
            )
            try repository.saveMembership(try membership.removed())
        }
    }

    private func perform(_ operation: () throws -> Void) {
        do {
            try operation()
            refresh(selecting: repository.loadSelectedChildID())
        } catch {
            errorMessage = resolveErrorMessage(for: error)
            refresh(selecting: repository.loadSelectedChildID())
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
        let invitedCaregivers = pairs.filter { pair in
            pair.membership.status == .invited
        }
        let removedCaregivers = pairs.filter { pair in
            pair.membership.status == .removed
        }

        return ChildProfileScreenState(
            child: child,
            localUser: localUser,
            currentMembership: currentMembership,
            owner: owner,
            activeCaregivers: activeCaregivers,
            invitedCaregivers: invitedCaregivers,
            removedCaregivers: removedCaregivers,
            canSwitchChildren: activeChildren.count > 1
        )
    }

    private func resolveErrorMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }

        return "Something went wrong. Please try again."
    }
}
