import BabyTrackerDomain
import BabyTrackerFeature
import BackgroundTasks
import Foundation

/// `BGTaskScheduler`-backed implementation of `BackgroundRefreshScheduling`.
/// Lives in the app target so the `BackgroundTasks` import stays out of
/// feature/preview code.
///
/// iOS treats the scheduling cadence as a hint, not a guarantee — the system
/// decides when (and whether) to actually run the task based on usage,
/// battery, and Low Power Mode.
@MainActor
final class SystemBackgroundRefreshScheduler: BackgroundRefreshScheduling {
    /// Must match the identifier listed in Info.plist under
    /// `BGTaskSchedulerPermittedIdentifiers`.
    static let taskIdentifier = "com.adappt.BabyTracker.backgroundRefresh"

    private static let earliestRefreshInterval: TimeInterval = 60 * 60

    private var handler: (@MainActor () async -> Bool)?
    private var didRegisterLaunchHandler = false

    init() {}

    func registerLaunchHandler(_ handler: @escaping @MainActor () async -> Bool) {
        self.handler = handler

        // BGTaskScheduler must only be registered once per identifier per
        // process, and must be wired before didFinishLaunchingWithOptions
        // returns.
        guard !didRegisterLaunchHandler else { return }
        didRegisterLaunchHandler = true

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let appRefreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            MainActor.assumeIsolated {
                self?.handle(task: appRefreshTask)
            }
        }
    }

    func scheduleNext() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: Self.earliestRefreshInterval)
        do {
            try BGTaskScheduler.shared.submit(request)
            AppLogger.shared.log(
                .debug,
                category: "BackgroundRefresh",
                "Scheduled next background refresh in \(Int(Self.earliestRefreshInterval))s"
            )
        } catch {
            AppLogger.shared.log(
                .warning,
                category: "BackgroundRefresh",
                "Failed to schedule background refresh: \(error.localizedDescription)"
            )
        }
    }

    private func handle(task: BGAppRefreshTask) {
        // Queue the next request before doing work so a crash or expiration
        // in this run still leaves a future refresh pending.
        scheduleNext()

        let work = Task { @MainActor in
            let success = await handler?() ?? false
            let cancelled = Task.isCancelled
            task.setTaskCompleted(success: success && !cancelled)
            AppLogger.shared.log(
                .info,
                category: "BackgroundRefresh",
                "Background refresh finished — success: \(success), expired: \(cancelled)"
            )
        }

        // Expiration runs on a system queue, so we can only do Sendable work
        // here. Cancelling the task lets the work block log the outcome itself.
        task.expirationHandler = {
            work.cancel()
        }
    }
}
