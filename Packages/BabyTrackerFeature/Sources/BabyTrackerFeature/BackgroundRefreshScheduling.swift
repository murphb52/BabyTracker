import Foundation

/// Abstraction over the platform background-task scheduler so feature code
/// stays free of `BackgroundTasks` imports. The composition root injects
/// either the system-backed implementation or a no-op for previews/tests.
@MainActor
public protocol BackgroundRefreshScheduling: AnyObject {
    /// Wires the closure the system should run when iOS hands the app a
    /// background slot. Implementations must register with the platform
    /// scheduler before launch finishes.
    func registerLaunchHandler(_ handler: @escaping () async -> Bool)

    /// Submits the next refresh request. Safe to call repeatedly — later
    /// calls replace earlier pending requests.
    func scheduleNext()
}
