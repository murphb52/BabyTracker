import BabyTrackerDomain
import Foundation
import Observation

/// Provides the home-screen state by computing directly from `AppModel` raw data.
@MainActor
@Observable
public final class HomeViewModel {
    private let appModel: AppModel

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    // MARK: - Computed state

    public var currentSleep: CurrentSleepCardViewState? {
        guard let activeSleep = appModel.activeSleep else { return nil }
        return CurrentSleepCardViewState(sleepEventID: activeSleep.id, startedAt: activeSleep.startedAt)
    }

    public var currentStatus: CurrentStatusCardViewState {
        guard let child = appModel.currentChild else {
            return CurrentStatusCardViewState(lastSleep: nil, lastBreastFeed: nil, lastBottleFeed: nil, feedsTodayCount: 0, lastNappy: nil)
        }
        return BuildCurrentStatusViewStateUseCase.execute(events: appModel.events, child: child, activeSleep: appModel.activeSleep)
    }

    public var recentEvents: [EventCardViewState] {
        guard let child = appModel.currentChild else { return [] }
        return Array(
            BuildEventCardsUseCase.execute(
                events: appModel.events,
                preferredFeedVolumeUnit: child.preferredFeedVolumeUnit
            ).prefix(6)
        )
    }

    public var syncStatus: CloudKitStatusViewState {
        appModel.cloudKitStatus
    }

    public var emptyStateTitle: String { "No recent activity" }

    public var emptyStateMessage: String { "Use Quick Log to add the first event." }

    public var canLogEvents: Bool {
        guard let membership = appModel.currentMembership else { return false }
        return ChildAccessPolicy.canPerform(.logEvent, membership: membership)
    }

    public var activeSleepSession: ActiveSleepSessionViewState? {
        appModel.activeSleep.map(ActiveSleepSessionViewState.init)
    }
}
