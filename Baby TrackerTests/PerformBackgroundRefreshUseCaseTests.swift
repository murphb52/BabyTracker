import BabyTrackerDomain
import BabyTrackerFeature
import Testing

@MainActor
struct PerformBackgroundRefreshUseCaseTests {
    @Test
    func reportsSuccessWhenSyncDoesNotFail() async {
        let refresher = StubBackgroundRefresher(state: .upToDate)
        let success = await PerformBackgroundRefreshUseCase.execute(refresher: refresher)
        #expect(success)
        #expect(refresher.recordedIsAppInBackground == true)
    }

    @Test
    func reportsFailureWhenSyncFails() async {
        let refresher = StubBackgroundRefresher(state: .failed)
        let success = await PerformBackgroundRefreshUseCase.execute(refresher: refresher)
        #expect(success == false)
    }
}

@MainActor
private final class StubBackgroundRefresher: BackgroundRefreshing {
    private let state: SyncState
    private(set) var recordedIsAppInBackground: Bool?

    init(state: SyncState) {
        self.state = state
    }

    func refreshAfterRemoteNotification(isAppInBackground: Bool) async -> SyncStatusSummary {
        recordedIsAppInBackground = isAppInBackground
        return SyncStatusSummary(state: state)
    }
}
