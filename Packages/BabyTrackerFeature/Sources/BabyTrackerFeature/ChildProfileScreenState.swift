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
    public let canLogFeeds: Bool
    public let canManageFeedEvents: Bool
    public let currentStateSummary: CurrentStateSummaryViewState?
    public let recentFeedEvents: [RecentFeedEventViewState]
    public let syncBannerState: SyncBannerState?
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
        canLogFeeds: Bool,
        canManageFeedEvents: Bool,
        currentStateSummary: CurrentStateSummaryViewState?,
        recentFeedEvents: [RecentFeedEventViewState],
        syncBannerState: SyncBannerState?,
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
        self.canLogFeeds = canLogFeeds
        self.canManageFeedEvents = canManageFeedEvents
        self.currentStateSummary = currentStateSummary
        self.recentFeedEvents = recentFeedEvents
        self.syncBannerState = syncBannerState
        self.canShareChild = canShareChild
    }
}
