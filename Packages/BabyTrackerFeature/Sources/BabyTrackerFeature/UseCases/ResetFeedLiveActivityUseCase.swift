import BabyTrackerDomain

/// Ends any live activity and clears the snapshot cache. Always tells the
/// manager to synchronize with `nil` so leaked or stale system activities
/// are reaped even if our cache thinks nothing is running.
public enum ResetFeedLiveActivityUseCase {
    private static let category = "LiveActivity"

    @MainActor
    public static func execute(
        liveActivityManager: any FeedLiveActivityManaging,
        snapshotCache: any FeedLiveActivitySnapshotCaching
    ) {
        let cacheHadValue = snapshotCache.load() != nil
        AppLogger.shared.log(
            .info,
            category: category,
            "[reset] entering — cacheHadValue=\(cacheHadValue) hasRunningActivity=\(liveActivityManager.hasRunningActivity)"
        )
        liveActivityManager.synchronize(with: nil)
        snapshotCache.save(nil)
        AppLogger.shared.log(.info, category: category, "[reset] complete")
    }
}
