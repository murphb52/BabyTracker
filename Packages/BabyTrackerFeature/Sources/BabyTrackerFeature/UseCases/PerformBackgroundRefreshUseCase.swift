import BabyTrackerDomain

/// Runs the same sync path used by silent push when iOS hands the app a
/// background-refresh slot. Returns whether the refresh succeeded so the
/// scheduler can hint the system about future scheduling.
public enum PerformBackgroundRefreshUseCase {
    @MainActor
    public static func execute(refresher: any BackgroundRefreshing) async -> Bool {
        let summary = await refresher.refreshAfterRemoteNotification(isAppInBackground: true)
        return summary.state != .failed
    }
}
