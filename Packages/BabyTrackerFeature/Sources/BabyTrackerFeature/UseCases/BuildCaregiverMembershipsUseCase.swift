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
        print("[Caregiver] BuildCaregiverMemberships: \(memberships.count) memberships, \(usersByID.count) users, \(pendingInvites.count) pending invites")
        for m in memberships {
            let userName = usersByID[m.userID]?.displayName ?? "(no user record)"
            print("[Caregiver]   Membership: userID=\(m.userID) role=\(m.role) status=\(m.status) user='\(userName)'")
        }

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

        let output = Output(
            owner: owner,
            activeCaregivers: activeCaregivers,
            pendingShareInvites: pendingInvites,
            removedCaregivers: removedCaregivers
        )
        print("[Caregiver] Result: owner=\(output.owner?.user.displayName ?? "none") active=\(output.activeCaregivers.count) pending=\(output.pendingShareInvites.count) removed=\(output.removedCaregivers.count)")
        return output
    }
}
