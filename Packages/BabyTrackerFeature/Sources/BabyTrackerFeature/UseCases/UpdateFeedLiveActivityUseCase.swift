import BabyTrackerDomain

/// Synchronizes the lock-screen live activity from the current in-memory profile state.
/// Skips the write when the snapshot is unchanged, preserving Apple's update budget.
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
            liveActivityManager.synchronize(with: nil)
            snapshotCache.save(nil)
            return
        }

        let snapshot = BuildFeedLiveActivitySnapshotUseCase.execute(
            events: events,
            child: child,
            activeSleep: activeSleep
        )

        // Bypass deduplication when no activity is running — the activity may have been
        // ended by the system (8-hour limit, low battery, user dismissal) while the
        // cached snapshot still matches, which would prevent a restart.
        let activityIsDead = !liveActivityManager.hasRunningActivity
        guard snapshot != snapshotCache.load() || activityIsDead else {
            return
        }

        liveActivityManager.synchronize(with: snapshot)
        snapshotCache.save(snapshot)
    }
}
