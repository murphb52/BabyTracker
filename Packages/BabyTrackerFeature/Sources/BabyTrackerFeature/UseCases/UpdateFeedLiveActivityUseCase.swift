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

        guard snapshot != snapshotCache.load() else {
            return
        }

        liveActivityManager.synchronize(with: snapshot)
        snapshotCache.save(snapshot)
    }
}
