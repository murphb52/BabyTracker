/// Clears the snapshot cache and ends the live activity.
/// Call this to force a full restart of the live activity — e.g. when
/// recovering from a stale state or when the user manually refreshes.
/// The next call to UpdateFeedLiveActivityUseCase will start a fresh activity.
public enum ResetFeedLiveActivityUseCase {
    @MainActor
    public static func execute(
        liveActivityManager: any FeedLiveActivityManaging,
        snapshotCache: any FeedLiveActivitySnapshotCaching
    ) {
        snapshotCache.save(nil)
        liveActivityManager.synchronize(with: nil)
    }
}
