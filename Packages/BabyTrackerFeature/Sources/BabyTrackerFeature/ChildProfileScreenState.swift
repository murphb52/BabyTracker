import BabyTrackerDomain
import Foundation

public struct ChildProfileScreenState: Equatable, Sendable {
    public let child: Child
    public let localUser: UserIdentity
    public let currentMembership: Membership
    public let owner: CaregiverMembershipViewState
    public let activeCaregivers: [CaregiverMembershipViewState]
    public let invitedCaregivers: [CaregiverMembershipViewState]
    public let removedCaregivers: [CaregiverMembershipViewState]
    public let canSwitchChildren: Bool

    public var canEditChild: Bool {
        ChildAccessPolicy.canPerform(.editChild, membership: currentMembership)
    }

    public var canArchiveChild: Bool {
        ChildAccessPolicy.canPerform(.archiveChild, membership: currentMembership)
    }

    public var canManageSharing: Bool {
        ChildAccessPolicy.canPerform(.inviteCaregiver, membership: currentMembership)
    }

    public init(
        child: Child,
        localUser: UserIdentity,
        currentMembership: Membership,
        owner: CaregiverMembershipViewState,
        activeCaregivers: [CaregiverMembershipViewState],
        invitedCaregivers: [CaregiverMembershipViewState],
        removedCaregivers: [CaregiverMembershipViewState],
        canSwitchChildren: Bool
    ) {
        self.child = child
        self.localUser = localUser
        self.currentMembership = currentMembership
        self.owner = owner
        self.activeCaregivers = activeCaregivers
        self.invitedCaregivers = invitedCaregivers
        self.removedCaregivers = removedCaregivers
        self.canSwitchChildren = canSwitchChildren
    }
}
