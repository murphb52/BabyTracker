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

    /// `earliestBeginDate` is a floor, not a request — iOS still applies its own
    /// budget on top. Keeping the floor short means the app is eligible for any
    /// slot the system is willing to grant, rather than sitting out the ones
    /// that come up sooner.
    private static let earliestRefreshInterval: TimeInterval = 15 * 60

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

        // Run the launch handler on the main queue (`using: .main`).
        //
        // The app target builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`,
        // so this closure is implicitly `@MainActor`-isolated and the Swift
        // runtime inserts an executor-isolation check at its entry point. With
        // the default queue (`using: nil`), BGTaskScheduler invokes the handler
        // on a private *background* queue, so that check (`dispatch_assert_queue`
        // for the main queue) fails and traps with EXC_BREAKPOINT before any of
        // our code runs. Dispatching on the main queue satisfies the MainActor
        // executor, so the check passes. The handler is trivial — it just kicks
        // off the actual async refresh work on the main actor.
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: .main
        ) { [weak self] task in
            guard let appRefreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self?.handle(task: appRefreshTask)
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

        // BGTaskScheduler traps if `setTaskCompleted` is called twice, and the
        // expiration handler can fire while the refresh is still in flight, so
        // both paths go through this.
        let completion = BackgroundTaskCompletion(task: task)

        // Installed before the work starts — expiration can fire immediately,
        // and a run with no handler yet installed is one iOS records against
        // the app.
        task.expirationHandler = {
            Task { @MainActor in
                completion.complete(success: false, expired: true)
            }
        }

        Task { @MainActor in
            let success = await self.handler?() ?? false
            completion.complete(success: success, expired: false)
        }
    }
}

/// Calls `setTaskCompleted` exactly once, whichever of the refresh and the
/// expiration handler finishes first.
@MainActor
private final class BackgroundTaskCompletion {
    private var task: BGAppRefreshTask?

    init(task: BGAppRefreshTask) {
        self.task = task
    }

    func complete(success: Bool, expired: Bool) {
        guard let task else {
            return
        }

        self.task = nil
        task.setTaskCompleted(success: success)
        AppLogger.shared.log(
            .info,
            category: "BackgroundRefresh",
            "Background refresh finished — success: \(success), expired: \(expired)"
        )
    }
}
