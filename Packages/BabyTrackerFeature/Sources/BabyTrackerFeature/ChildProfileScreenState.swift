import BabyTrackerDomain
import Foundation

public struct ChildProfileScreenState: Equatable, Sendable {
    public let child: Child
    public let localUser: UserIdentity
    public let currentMembership: Membership
    public let owner: CaregiverMembershipViewState
    public let activeCaregivers: [CaregiverMembershipViewState]
    public let pendingShareInvites: [PendingShareInviteViewState]
    public let removedCaregivers: [CaregiverMembershipViewState]
    public let canSwitchChildren: Bool
    public let canLogEvents: Bool
    public let canManageEvents: Bool
    public let activeSleepSession: ActiveSleepSessionViewState?
    public let currentStateSummary: CurrentStateSummaryViewState?
    public let recentFeedEvents: [RecentFeedEventViewState]
    public let recentSleepEvents: [RecentSleepEventViewState]
    public let recentNappyEvents: [RecentNappyEventViewState]
    public let cloudKitStatus: CloudKitStatusViewState
    public let canShareChild: Bool

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
        pendingShareInvites: [PendingShareInviteViewState],
        removedCaregivers: [CaregiverMembershipViewState],
        canSwitchChildren: Bool,
        canLogEvents: Bool,
        canManageEvents: Bool,
        activeSleepSession: ActiveSleepSessionViewState?,
        currentStateSummary: CurrentStateSummaryViewState?,
        recentFeedEvents: [RecentFeedEventViewState],
        recentSleepEvents: [RecentSleepEventViewState],
        recentNappyEvents: [RecentNappyEventViewState],
        cloudKitStatus: CloudKitStatusViewState,
        canShareChild: Bool
    ) {
        self.child = child
        self.localUser = localUser
        self.currentMembership = currentMembership
        self.owner = owner
        self.activeCaregivers = activeCaregivers
        self.pendingShareInvites = pendingShareInvites
        self.removedCaregivers = removedCaregivers
        self.canSwitchChildren = canSwitchChildren
        self.canLogEvents = canLogEvents
        self.canManageEvents = canManageEvents
        self.activeSleepSession = activeSleepSession
        self.currentStateSummary = currentStateSummary
        self.recentFeedEvents = recentFeedEvents
        self.recentSleepEvents = recentSleepEvents
        self.recentNappyEvents = recentNappyEvents
        self.cloudKitStatus = cloudKitStatus
        self.canShareChild = canShareChild
    }
}
