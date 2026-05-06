@testable import BabyTrackerFeature

@MainActor
final class SpyFeedLiveActivityManager: FeedLiveActivityManaging {
    var hasRunningActivity: Bool = false
    var systemAuthorizationGranted: Bool = true
    var stubbedRunningActivityIDs: [String] = []
    var stubbedActiveActivityID: String?
    var stubbedLastSyncSummary: String?
    private(set) var synchronizeCalls: [FeedLiveActivitySnapshot?] = []
    private(set) var diagnosticCallCount: Int = 0

    func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        synchronizeCalls.append(snapshot)
    }

    func currentDiagnostic() -> FeedLiveActivityDiagnostic {
        diagnosticCallCount += 1
        return FeedLiveActivityDiagnostic(
            hasRunningActivity: hasRunningActivity,
            activeActivityID: stubbedActiveActivityID,
            runningActivityIDs: stubbedRunningActivityIDs,
            systemAuthorizationGranted: systemAuthorizationGranted,
            lastSyncSummary: stubbedLastSyncSummary
        )
    }
}
