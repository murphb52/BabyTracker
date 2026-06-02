import BabyTrackerDomain

/// Synchronizes the lock-screen live activity from the current in-memory profile state.
///
/// Deduplication is intentionally *not* done here. The `FeedLiveActivityManaging`
/// implementation dedups against the activity's actual on-screen content, which is
/// the only reliable source of truth — a shadow cache here could (and did) silently
/// disagree with ActivityKit and leave the activity stuck on stale data while every
/// refresh skipped the update.
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

        guard let snapshot else {
            AppLogger.shared.log(
                .info,
                category: "LiveActivity",
                "Update produced no snapshot — no feed data yet for \(child.name); ending activity"
            )
            liveActivityManager.synchronize(with: nil)
            return
        }

        AppLogger.shared.log(
            .info,
            category: "LiveActivity",
            "Synchronizing Live Activity for \(child.name)"
        )
        liveActivityManager.synchronize(with: snapshot)
    }
}
