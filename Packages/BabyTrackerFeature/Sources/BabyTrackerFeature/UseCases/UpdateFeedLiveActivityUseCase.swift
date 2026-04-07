import BabyTrackerDomain

/// Synchronizes the lock-screen live activity from the current in-memory profile state.
public enum UpdateFeedLiveActivityUseCase {
    @MainActor
    public static func execute(
        events: [BabyEvent],
        child: Child?,
        activeSleep: SleepEvent?,
        isLiveActivityEnabled: Bool,
        liveActivityManager: any FeedLiveActivityManaging
    ) {
        guard isLiveActivityEnabled, let child else {
            liveActivityManager.synchronize(with: nil)
            return
        }

        let snapshot = BuildFeedLiveActivitySnapshotUseCase.execute(
            events: events,
            child: child,
            activeSleep: activeSleep
        )
        liveActivityManager.synchronize(with: snapshot)
    }
}
