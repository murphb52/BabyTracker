import BabyTrackerDomain
import Foundation

/// Buckets a flat list of memberships + users into the four caregiver groups
/// required by the profile screen: owner, active caregivers, pending invites,
/// and removed caregivers.
public enum BuildCaregiverMembershipsUseCase {
    public struct Output {
        public let owner: CaregiverMembershipViewState?
        public let activeCaregivers: [CaregiverMembershipViewState]
        public let pendingShareInvites: [PendingShareInviteViewState]
        public let removedCaregivers: [CaregiverMembershipViewState]
    }

    public static func execute(
        memberships: [Membership],
        usersByID: [UUID: UserIdentity],
        pendingInvites: [PendingShareInviteViewState]
    ) -> Output {
        let pairs = memberships.compactMap { membership -> CaregiverMembershipViewState? in
            guard let user = usersByID[membership.userID] else { return nil }
            return CaregiverMembershipViewState(user: user, membership: membership)
        }

        let owner = pairs.first {
            $0.membership.role == .owner && $0.membership.status == .active
        }
        let activeCaregivers = pairs.filter {
            $0.membership.role == .caregiver && $0.membership.status == .active
        }
        let removedCaregivers = pairs.filter {
            $0.membership.status == .removed
        }

        return Output(
            owner: owner,
            activeCaregivers: activeCaregivers,
            pendingShareInvites: pendingInvites,
            removedCaregivers: removedCaregivers
        )
    }
}
