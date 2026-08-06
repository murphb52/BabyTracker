import BabyTrackerDomain
import Foundation

/// How long a background wake-up waits for a sync before reporting back to iOS.
///
/// iOS gives a silent-push wake-up or a `BGAppRefreshTask` roughly 30 seconds
/// to report a result. An app that misses that window is killed and has its
/// future background wake-ups throttled, so the budget here is deliberately
/// well inside it.
public let backgroundRefreshTimeout: Duration = .seconds(20)

/// Waits for `work`, giving up and returning `nil` once `timeout` elapses.
///
/// `work` is deliberately left running. A CloudKit request stalled on a weak
/// network is routine in the background, and the goal is not to abandon the
/// sync — it is to always hand iOS a result inside the window it allows, so it
/// keeps waking the app.
@MainActor
func backgroundRefreshSummary(
    from work: Task<SyncStatusSummary, Never>,
    within timeout: Duration
) async -> SyncStatusSummary? {
    await withCheckedContinuation { continuation in
        let race = FirstFinisher(continuation)

        Task { @MainActor in
            let summary = await work.value
            race.finish(with: summary)
        }

        Task { @MainActor in
            try? await Task.sleep(for: timeout)
            race.finish(with: nil)
        }
    }
}

/// Resumes a continuation exactly once, for whichever racing task reaches it
/// first. Main-actor isolated, so the "already resumed" check needs no lock.
@MainActor
private final class FirstFinisher {
    private var continuation: CheckedContinuation<SyncStatusSummary?, Never>?

    init(_ continuation: CheckedContinuation<SyncStatusSummary?, Never>) {
        self.continuation = continuation
    }

    func finish(with summary: SyncStatusSummary?) {
        guard let continuation else {
            return
        }

        self.continuation = nil
        continuation.resume(returning: summary)
    }
}
