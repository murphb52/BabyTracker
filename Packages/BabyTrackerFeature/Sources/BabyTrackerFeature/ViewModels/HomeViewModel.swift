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

    public var childName: String? {
        appModel.currentChild?.name
    }

    /// The time the child woke up (endedAt of most recent completed sleep), shown in the awake hero card.
    /// Nil when no prior sleep is recorded or an active sleep is in progress.
    public var awakeHeroCard: HomeAwakeHeroCardViewState? {
        guard appModel.activeSleep == nil else { return nil }
        return HomeAwakeHeroCardViewState(awakeStartedAt: currentStatus.lastSleep?.endedAt)
    }

    /// The six most recent events shaped for the Today timeline on the home screen.
    public var todayTimelineEvents: [HomeTimelineEventViewState] {
        guard let child = appModel.currentChild else { return [] }
        let preferredUnit = child.preferredFeedVolumeUnit
        let activeSleepID = appModel.activeSleep?.id

        return Array(appModel.events.prefix(6)).compactMap { event -> HomeTimelineEventViewState? in
            let id: UUID
            let kind: BabyEventKind
            let occurredAt: Date

            switch event {
            case let .breastFeed(feed):
                id = feed.id
                kind = .breastFeed
                occurredAt = feed.metadata.occurredAt
            case let .bottleFeed(feed):
                id = feed.id
                kind = .bottleFeed
                occurredAt = feed.metadata.occurredAt
            case let .sleep(sleep):
                id = sleep.id
                kind = .sleep
                occurredAt = sleep.metadata.occurredAt
            case let .nappy(nappy):
                id = nappy.id
                kind = .nappy
                occurredAt = nappy.metadata.occurredAt
            }

            return HomeTimelineEventViewState(
                id: id,
                kind: kind,
                title: BabyEventPresentation.title(for: event),
                detailText: BabyEventPresentation.detailText(for: event, preferredFeedVolumeUnit: preferredUnit) ?? "",
                timeText: occurredAt.formatted(.dateTime.hour().minute()),
                isOngoing: activeSleepID.map { $0 == id } ?? false
            )
        }
    }
}
