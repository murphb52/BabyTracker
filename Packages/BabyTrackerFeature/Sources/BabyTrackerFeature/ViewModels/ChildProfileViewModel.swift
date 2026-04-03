import BabyTrackerDomain
import Foundation
import Observation

/// Provides child profile screen state by observing `AppModel.profile`.
///
/// Currently bridges `profile.*` for child data, permissions, caregivers,
/// and sharing. Exposes `profile` directly for sub-views that still depend
/// on `ChildProfileScreenState`. When `ChildProfileScreenState` is removed
/// (Stage 10) these will be computed directly from raw AppModel data using
/// `BuildCaregiverMembershipsUseCase` and related UseCases.
@MainActor
@Observable
public final class ChildProfileViewModel {
    private let appModel: AppModel

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    // MARK: - Raw profile access (for sub-views still using ChildProfileScreenState)

    public var profile: ChildProfileScreenState? {
        appModel.profile
    }

    // MARK: - Child data

    public var child: Child? {
        appModel.profile?.child
    }

    public var childName: String {
        appModel.profile?.child.name ?? ""
    }

    // MARK: - User & membership

    public var localUser: UserIdentity? {
        appModel.profile?.localUser
    }

    public var currentMembership: Membership? {
        appModel.profile?.currentMembership
    }

    // MARK: - Permissions

    public var canLogEvents: Bool {
        appModel.profile?.canLogEvents ?? false
    }

    public var canManageEvents: Bool {
        appModel.profile?.canManageEvents ?? false
    }

    public var canShareChild: Bool {
        appModel.profile?.canShareChild ?? false
    }

    public var canEditChild: Bool {
        appModel.profile?.canEditChild ?? false
    }

    public var canArchiveChild: Bool {
        appModel.profile?.canArchiveChild ?? false
    }

    public var canHardDelete: Bool {
        appModel.profile?.canHardDelete ?? false
    }

    public var canLeaveShare: Bool {
        appModel.profile?.canLeaveShare ?? false
    }

    public var canManageSharing: Bool {
        appModel.profile?.canManageSharing ?? false
    }

    public var canCreateLocalChild: Bool {
        appModel.profile?.canCreateLocalChild ?? false
    }

    // MARK: - Caregivers & sharing

    public var owner: CaregiverMembershipViewState? {
        appModel.profile?.owner
    }

    public var activeCaregivers: [CaregiverMembershipViewState] {
        appModel.profile?.activeCaregivers ?? []
    }

    public var pendingShareInvites: [PendingShareInviteViewState] {
        appModel.profile?.pendingShareInvites ?? []
    }

    public var removedCaregivers: [CaregiverMembershipViewState] {
        appModel.profile?.removedCaregivers ?? []
    }

    // MARK: - Sync & events

    public var cloudKitStatus: CloudKitStatusViewState {
        appModel.profile?.cloudKitStatus ?? CloudKitStatusViewState(summary: SyncStatusSummary())
    }

    public var latestEventSyncMarker: EventSyncMarkerViewState? {
        appModel.profile?.latestEventSyncMarker
    }

    public var totalEventCount: Int {
        appModel.profile?.totalEventCount ?? 0
    }

    public var pendingChanges: [PendingChangeSummaryItem] {
        appModel.profile?.pendingChanges ?? []
    }

    public var activeSleepSession: ActiveSleepSessionViewState? {
        appModel.profile?.activeSleepSession
    }

    // MARK: - Child list

    public var availableChildren: [ChildSummary] {
        appModel.profile?.availableChildren ?? []
    }
}
