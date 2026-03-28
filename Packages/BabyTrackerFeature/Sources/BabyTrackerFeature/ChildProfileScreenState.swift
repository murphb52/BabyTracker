import BabyTrackerDomain
import Foundation

public struct ChildProfileScreenState: Equatable, Sendable {
    public let child: Child
    public let localUser: UserIdentity
    public let currentMembership: Membership
    public let owner: CaregiverMembershipViewState?
    public let activeCaregivers: [CaregiverMembershipViewState]
    public let pendingShareInvites: [PendingShareInviteViewState]
    public let removedCaregivers: [CaregiverMembershipViewState]
    public let canLogEvents: Bool
    public let canManageEvents: Bool
    public let activeSleepSession: ActiveSleepSessionViewState?
    public let home: HomeScreenState
    public let eventHistory: EventHistoryScreenState
    public let timeline: TimelineScreenState
    public let summary: SummaryScreenState
    public let cloudKitStatus: CloudKitStatusViewState
    public let canShareChild: Bool
    public let pendingChanges: [PendingChangeSummaryItem]
    public let availableChildren: [ChildSummary]
    public let canCreateLocalChild: Bool

    public var canEditChild: Bool {
        ChildAccessPolicy.canPerform(.editChild, membership: currentMembership)
    }

    public var canArchiveChild: Bool {
        ChildAccessPolicy.canPerform(.archiveChild, membership: currentMembership)
    }

    public var canManageSharing: Bool {
        ChildAccessPolicy.canPerform(.inviteCaregiver, membership: currentMembership)
    }

    public var canHardDelete: Bool {
        ChildAccessPolicy.isActiveOwner(currentMembership)
    }

    public var canLeaveShare: Bool {
        currentMembership.role == .caregiver && currentMembership.status == .active
    }

    public init(
        child: Child,
        localUser: UserIdentity,
        currentMembership: Membership,
        owner: CaregiverMembershipViewState?,
        activeCaregivers: [CaregiverMembershipViewState],
        pendingShareInvites: [PendingShareInviteViewState],
        removedCaregivers: [CaregiverMembershipViewState],
        canLogEvents: Bool,
        canManageEvents: Bool,
        activeSleepSession: ActiveSleepSessionViewState?,
        home: HomeScreenState,
        eventHistory: EventHistoryScreenState,
        timeline: TimelineScreenState,
        summary: SummaryScreenState,
        cloudKitStatus: CloudKitStatusViewState,
        canShareChild: Bool,
        pendingChanges: [PendingChangeSummaryItem] = [],
        availableChildren: [ChildSummary] = [],
        canCreateLocalChild: Bool = false
    ) {
        self.child = child
        self.localUser = localUser
        self.currentMembership = currentMembership
        self.owner = owner
        self.activeCaregivers = activeCaregivers
        self.pendingShareInvites = pendingShareInvites
        self.removedCaregivers = removedCaregivers
        self.canLogEvents = canLogEvents
        self.canManageEvents = canManageEvents
        self.activeSleepSession = activeSleepSession
        self.home = home
        self.eventHistory = eventHistory
        self.timeline = timeline
        self.summary = summary
        self.cloudKitStatus = cloudKitStatus
        self.canShareChild = canShareChild
        self.pendingChanges = pendingChanges
        self.availableChildren = availableChildren
        self.canCreateLocalChild = canCreateLocalChild
    }
}
