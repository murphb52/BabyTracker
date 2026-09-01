import BabyTrackerDomain
import Foundation

/// Single entry point for keeping the lock-screen Live Activity in sync with
/// the current profile state.
///
/// Builds the desired snapshot and hands it to the manager. A `nil` snapshot
/// (feature disabled, no selected child, or no feed data yet) ends the
/// activity. All deduplication and lifecycle policy lives in the
/// `FeedLiveActivityManaging` implementation, which reconciles against
/// ActivityKit's actual on-screen content — never a shadow cache.
public enum SyncFeedLiveActivityUseCase {
    @MainActor
    public static func execute(
        events: [BabyEvent],
        child: Child?,
        activeSleep: SleepEvent?,
        isLiveActivityEnabled: Bool,
        liveActivityManager: any FeedLiveActivityManaging
    ) {
        let snapshot = makeSnapshot(
            events: events,
            child: child,
            activeSleep: activeSleep,
            isLiveActivityEnabled: isLiveActivityEnabled
        )

        if snapshot == nil {
            AppLogger.shared.log(
                .info,
                category: "LiveActivity",
                "Sync resolved to no activity — \(reasonForNoSnapshot(child: child, isLiveActivityEnabled: isLiveActivityEnabled))"
            )
        }

        liveActivityManager.synchronize(with: snapshot)
    }

    /// Pure snapshot construction, exposed separately so tests can verify the
    /// mapping without a manager.
    public static func makeSnapshot(
        events: [BabyEvent],
        child: Child?,
        activeSleep: SleepEvent?,
        isLiveActivityEnabled: Bool
    ) -> FeedLiveActivitySnapshot? {
        guard isLiveActivityEnabled, let child else {
            return nil
        }

        // The compact Feed tile represents the latest nutrition event. Summary
        // feed intervals remain milk-only elsewhere in the app.
        let feedKinds: Set<BabyEventKind> = [.breastFeed, .bottleFeed, .food]
        guard let latestFeed = events
            .filter({ feedKinds.contains($0.kind) })
            .max(by: { $0.metadata.occurredAt < $1.metadata.occurredAt }) else {
            return nil
        }

        let lastSleep = LastSleepSummaryCalculator.makeSummary(
            from: events,
            activeSleep: activeSleep
        )
        let lastNappy = LastNappySummaryCalculator.makeSummary(from: events)

        return FeedLiveActivitySnapshot(
            childID: child.id,
            childName: child.name,
            lastFeedKind: latestFeed.kind,
            lastFeedAt: latestFeed.metadata.occurredAt,
            lastSleepAt: lastSleep?.endedAt ?? lastSleep?.startedAt,
            activeSleepStartedAt: lastSleep?.isActive == true ? lastSleep?.startedAt : nil,
            lastNappyAt: lastNappy?.occurredAt
        )
    }

    private static func reasonForNoSnapshot(
        child: Child?,
        isLiveActivityEnabled: Bool
    ) -> String {
        if !isLiveActivityEnabled {
            return "toggle disabled"
        }
        if child == nil {
            return "no selected child"
        }
        return "no feed data yet"
    }
}
