import BabyTrackerDomain

/// Ends the live activity (and the manager clears the snapshot cache once it has
/// actually ended), but only if an activity is currently running. Call this to
/// force a full restart — the next UpdateFeedLiveActivityUseCase call will start
/// a fresh activity regardless of previously cached state.
///
/// "Is an activity running" is read straight from the manager rather than the
/// snapshot cache: the cache is owned by the manager and only advances once an
/// ActivityKit write has landed, so it is not a reliable standalone signal here.
public enum ResetFeedLiveActivityUseCase {
    @MainActor
    public static func execute(
        liveActivityManager: any FeedLiveActivityManaging
    ) {
        guard liveActivityManager.hasRunningActivity else {
            return
        }
        AppLogger.shared.log(.info, category: "LiveActivity", "Reset — ending Live Activity and clearing cache")
        liveActivityManager.synchronize(with: nil)
    }
}
