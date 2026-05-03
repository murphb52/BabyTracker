import BabyTrackerDomain
import BackgroundTasks
import Foundation

/// Schedules and runs an opportunistic background refresh on top of CloudKit
/// silent push. Push delivery is best-effort, so this gives the app a second
/// independent chance to pull caregiver changes while suspended.
///
/// iOS treats the requested cadence as a hint, not a guarantee — the system
/// decides when (and whether) to actually run the task based on usage,
/// battery, and Low Power Mode.
@MainActor
final class BackgroundAppRefreshScheduler {
    static let shared = BackgroundAppRefreshScheduler()

    /// Must match the identifier listed in Info.plist under
    /// `BGTaskSchedulerPermittedIdentifiers`.
    static let taskIdentifier = "com.adappt.BabyTracker.backgroundRefresh"

    private static let earliestRefreshInterval: TimeInterval = 60 * 60

    /// Set by the composition root to perform the actual refresh. Returns
    /// whether the refresh succeeded so the system can adapt scheduling.
    var handler: (() async -> Bool)?

    private var didRegisterLaunchHandler = false

    private init() {}

    func registerLaunchHandler() {
        // BGTaskScheduler must only be registered once per identifier per
        // process and must be wired before didFinishLaunchingWithOptions
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
