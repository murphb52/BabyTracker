import BabyTrackerDomain

/// Ends the live activity and clears the snapshot cache, but only if the
/// cache contains data (i.e. a live activity is actually running).
/// Call this to force a full restart — the next UpdateFeedLiveActivityUseCase
/// call will start a fresh activity regardless of previously cached state.
public enum ResetFeedLiveActivityUseCase {
    @MainActor
    public static func execute(
        liveActivityManager: any FeedLiveActivityManaging,
        snapshotCache: any FeedLiveActivitySnapshotCaching
    ) {
        guard snapshotCache.load() != nil else {
            return
        }
        AppLogger.shared.log(.info, category: "LiveActivity", "Reset — ending Live Activity and clearing cache")
        // The manager clears the snapshot cache once the activity has actually ended.
        liveActivityManager.synchronize(with: nil)
    }
}
