import BabyTrackerDomain
import Foundation
import Observation

/// Provides child profile screen state computed directly from `AppModel` flat data.
@MainActor
@Observable
public final class ChildProfileViewModel {
    private let appModel: AppModel

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    // MARK: - Child data

    public var child: Child? {
        appModel.currentChild
    }

    public var childName: String {
        appModel.currentChild?.name ?? ""
    }

    // MARK: - User & membership

    public var localUser: UserIdentity? {
        appModel.localUser
    }

    public var currentMembership: Membership? {
        appModel.currentMembership
    }

    // MARK: - Permissions

    public var canLogEvents: Bool {
        guard let m = appModel.currentMembership else { return false }
        return ChildAccessPolicy.canPerform(.logEvent, membership: m)
    }

    public var canManageEvents: Bool {
        guard let m = appModel.currentMembership else { return false }
        return ChildAccessPolicy.canPerform(.editEvent, membership: m)
            && ChildAccessPolicy.canPerform(.deleteEvent, membership: m)
    }

    public var canShareChild: Bool {
        guard let m = appModel.currentMembership else { return false }
        return ChildAccessPolicy.canPerform(.inviteCaregiver, membership: m)
            && appModel.cloudKitStatus.state != .failed
    }

    public var canEditChild: Bool {
        guard let m = appModel.currentMembership else { return false }
        return ChildAccessPolicy.canPerform(.editChild, membership: m)
    }

    public var canArchiveChild: Bool {
        guard let m = appModel.currentMembership else { return false }
        return ChildAccessPolicy.canPerform(.archiveChild, membership: m)
    }

    public var canHardDelete: Bool {
        guard let m = appModel.currentMembership else { return false }
        return ChildAccessPolicy.isActiveOwner(m)
    }

    public var canLeaveShare: Bool {
        guard let m = appModel.currentMembership else { return false }
        return m.role == .caregiver && m.status == .active
    }

    public var canManageSharing: Bool {
        guard let m = appModel.currentMembership else { return false }
        return ChildAccessPolicy.canPerform(.inviteCaregiver, membership: m)
    }

    public var canCreateLocalChild: Bool {
        appModel.localUser != nil
    }

    // MARK: - Caregivers & sharing

    private var caregiverOutput: BuildCaregiverMembershipsUseCase.Output {
        let usersByID = Dictionary(uniqueKeysWithValues: appModel.membershipUsers.map { ($0.id, $0) })
        return BuildCaregiverMembershipsUseCase.execute(
            memberships: appModel.memberships,
            usersByID: usersByID,
            pendingInvites: appModel.pendingShareInvites
        )
    }

    public var owner: CaregiverMembershipViewState? {
        caregiverOutput.owner
    }

    public var activeCaregivers: [CaregiverMembershipViewState] {
        caregiverOutput.activeCaregivers
    }

    public var pendingShareInvites: [PendingShareInviteViewState] {
        caregiverOutput.pendingShareInvites
    }

    public var removedCaregivers: [CaregiverMembershipViewState] {
        caregiverOutput.removedCaregivers
    }

    // MARK: - Sync & events

    public var cloudKitStatus: CloudKitStatusViewState {
        appModel.cloudKitStatus
    }

    public var latestEventSyncMarker: EventSyncMarkerViewState? {
        BuildLatestEventSyncMarkerUseCase.execute(events: appModel.events)
    }

    public var totalEventCount: Int {
        appModel.events.count
    }

    public var pendingChanges: [PendingChangeSummaryItem] {
        appModel.pendingChanges
    }

    public var activeSleepSession: ActiveSleepSessionViewState? {
        appModel.activeSleep.map(ActiveSleepSessionViewState.init)
    }

    // MARK: - Child list

    public var availableChildren: [ChildSummary] {
        appModel.activeChildren
    }
}
