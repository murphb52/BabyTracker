import BabyTrackerDomain

/// Runs the same sync path used by silent push when iOS hands the app a
/// background-refresh slot. Returns whether the refresh succeeded so the
/// scheduler can hint the system about future scheduling.
public enum PerformBackgroundRefreshUseCase {
    @MainActor
    public static func execute(refresher: any BackgroundRefreshing) async -> Bool {
        AppLogger.shared.log(.info, category: "BackgroundRefresh", "[useCase] starting refreshAfterRemoteNotification")
        let summary = await refresher.refreshAfterRemoteNotification(isAppInBackground: true)
        let succeeded = summary.state != .failed
        AppLogger.shared.log(
            .info,
            category: "BackgroundRefresh",
            "[useCase] finished — state=\(String(describing: summary.state)) success=\(succeeded)"
        )
        return succeeded
    }
}
