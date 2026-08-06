import BabyTrackerDomain

/// Runs the same sync path used by silent push when iOS hands the app a
/// background-refresh slot. Returns whether the refresh succeeded so the
/// scheduler can hint the system about future scheduling.
public enum PerformBackgroundRefreshUseCase {
    @MainActor
    public static func execute(
        refresher: any BackgroundRefreshing,
        timeout: Duration = backgroundRefreshTimeout
    ) async -> Bool {
        let summary = await refresher.refreshAfterRemoteNotification(
            isAppInBackground: true,
            timeout: timeout
        )
        return summary.state != .failed
    }
}
