import BabyTrackerDomain

/// Synchronizes the lock-screen live activity from the current in-memory profile state.
/// Skips the write when the snapshot is unchanged, preserving Apple's update budget.
///
/// The snapshot cache is read here as the dedup oracle but written by the
/// `FeedLiveActivityManaging` implementation once the ActivityKit write actually
/// lands. Persisting it here optimistically would let the cache run ahead of the
/// live activity whenever an update is interrupted (background suspension, task
/// cancellation), which permanently dedups every later update and leaves the
/// activity stuck on stale data.
public enum UpdateFeedLiveActivityUseCase {
    @MainActor
    public static func execute(
        events: [BabyEvent],
        child: Child?,
        activeSleep: SleepEvent?,
        isLiveActivityEnabled: Bool,
        liveActivityManager: any FeedLiveActivityManaging,
        snapshotCache: any FeedLiveActivitySnapshotCaching
    ) {
        guard isLiveActivityEnabled, let child else {
            AppLogger.shared.log(
                .info,
                category: "LiveActivity",
                "Update skipped — \(isLiveActivityEnabled ? "no selected child" : "toggle disabled"); ending activity"
            )
            liveActivityManager.synchronize(with: nil)
            return
        }

        let snapshot = BuildFeedLiveActivitySnapshotUseCase.execute(
            events: events,
            child: child,
            activeSleep: activeSleep
        )

        guard snapshot != nil else {
            AppLogger.shared.log(
                .info,
                category: "LiveActivity",
                "Update produced no snapshot — no feed data yet for \(child.name); ending activity"
            )
            liveActivityManager.synchronize(with: nil)
            return
        }

        // Bypass deduplication when no activity is running — the activity may have been
        // ended by the system (8-hour limit, low battery, user dismissal) while the
        // cached snapshot still matches, which would prevent a restart.
        let activityIsDead = !liveActivityManager.hasRunningActivity
        guard snapshot != snapshotCache.load() || activityIsDead else {
            AppLogger.shared.log(
                .debug,
                category: "LiveActivity",
                "Update deduped — snapshot unchanged and activity already running"
            )
            return
        }

        AppLogger.shared.log(
            .info,
            category: "LiveActivity",
            "Synchronizing Live Activity (activityIsDead: \(activityIsDead))"
        )
        liveActivityManager.synchronize(with: snapshot)
    }
}
