import BabyTrackerDomain
import Foundation
import Observation

/// Provides the home-screen state by observing `AppModel.profile`.
///
/// Currently bridges `profile.home.*`, `profile.activeSleepSession`,
/// and `profile.canLogEvents`. When `ChildProfileScreenState` is removed
/// (Stage 10) these will be computed directly from raw AppModel data
/// using `BuildCurrentStatusViewStateUseCase`, `BuildEventCardsUseCase`,
/// and `GetActiveSleepUseCase`.
@MainActor
@Observable
public final class HomeViewModel {
    private let appModel: AppModel

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    // MARK: - Computed state

    public var currentSleep: CurrentSleepCardViewState? {
        appModel.profile?.home.currentSleep
    }

    public var currentStatus: CurrentStatusCardViewState {
        appModel.profile?.home.currentStatus ?? CurrentStatusCardViewState(
            timeSinceLastFeedAt: nil,
            feedsTodayCount: 0,
            timeSinceLastNappyAt: nil
        )
    }

    public var recentEvents: [EventCardViewState] {
        appModel.profile?.home.recentEvents ?? []
    }

    public var syncStatus: CloudKitStatusViewState {
        appModel.profile?.home.syncStatus ?? CloudKitStatusViewState(summary: SyncStatusSummary())
    }

    public var emptyStateTitle: String {
        appModel.profile?.home.emptyStateTitle ?? "No recent activity"
    }

    public var emptyStateMessage: String {
        appModel.profile?.home.emptyStateMessage ?? "Use Quick Log to add the first event."
    }

    public var canLogEvents: Bool {
        appModel.profile?.canLogEvents ?? false
    }

    public var activeSleepSession: ActiveSleepSessionViewState? {
        appModel.profile?.activeSleepSession
    }
}
