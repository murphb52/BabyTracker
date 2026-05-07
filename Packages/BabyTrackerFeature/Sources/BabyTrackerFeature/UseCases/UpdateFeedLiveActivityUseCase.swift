import BabyTrackerDomain

/// Synchronizes the lock-screen live activity from the current in-memory profile state.
/// Skips the write when the snapshot is unchanged, preserving Apple's update budget.
public enum UpdateFeedLiveActivityUseCase {
    private static let category = "LiveActivity"

    @MainActor
    public static func execute(
        events: [BabyEvent],
        child: Child?,
        activeSleep: SleepEvent?,
        isLiveActivityEnabled: Bool,
        liveActivityManager: any FeedLiveActivityManaging,
        snapshotCache: any FeedLiveActivitySnapshotCaching
    ) {
        AppLogger.shared.log(
            .debug,
            category: category,
            "[update] entering enabled=\(isLiveActivityEnabled) child=\(child?.id.uuidString.prefix(8).description ?? "nil") events=\(events.count) activeSleep=\(activeSleep != nil)"
        )

        guard isLiveActivityEnabled else {
            AppLogger.shared.log(.info, category: category, "[update] skip — preference disabled; clearing activity & cache")
            liveActivityManager.synchronize(with: nil)
            snapshotCache.save(nil)
            return
        }

        guard let child else {
            AppLogger.shared.log(.info, category: category, "[update] skip — no current child; clearing activity & cache")
            liveActivityManager.synchronize(with: nil)
            snapshotCache.save(nil)
            return
        }

        let snapshot = BuildFeedLiveActivitySnapshotUseCase.execute(
            events: events,
            child: child,
            activeSleep: activeSleep
        )

        guard let snapshot else {
            AppLogger.shared.log(.info, category: category, "[update] skip — snapshot is nil (no feed events yet); clearing activity & cache")
            liveActivityManager.synchronize(with: nil)
            snapshotCache.save(nil)
            return
        }

        let cached = snapshotCache.load()
        // Bypass deduplication when no activity is running — the activity may have been
        // ended by the system (8-hour limit, low battery, user dismissal) while the
        // cached snapshot still matches, which would prevent a restart.
        let activityIsDead = !liveActivityManager.hasRunningActivity
        let unchanged = snapshot == cached

        if unchanged && !activityIsDead {
            AppLogger.shared.log(
                .debug,
                category: category,
                "[update] skip — snapshot unchanged & activity alive"
            )
            return
        }

        if unchanged && activityIsDead {
            AppLogger.shared.log(
                .info,
                category: category,
                "[update] forcing — activity dead despite cached snapshot match (system likely ended it)"
            )
        } else {
            AppLogger.shared.log(
                .info,
                category: category,
                "[update] syncing — snapshot changed (cache=\(cached == nil ? "nil" : "present"))"
            )
        }

        liveActivityManager.synchronize(with: snapshot)
        snapshotCache.save(snapshot)
    }
}
