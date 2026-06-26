import Dispatch
import Foundation
import os

/// Lightweight, dependency-free performance instrumentation used to measure the
/// app's launch / refresh / data-loading hot paths.
///
/// Everything funnels through a single `os.Logger` category ("Performance") and a
/// matching `OSSignposter`, so the output is:
///   - filterable in Console.app / `log stream` via
///     `subsystem == "com.adappt.BabyTracker" && category == "Performance"`
///   - visible as intervals in Instruments (os_signpost)
///
/// The log lines are intentionally **stable** (fixed prefixes + labels) so that a
/// "before" capture and an "after" capture can be diffed mechanically. When the
/// data-loading refactor lands, the same lines keep emitting and the numbers move.
///
/// To pull a capture from a device build:
///   log stream --predicate 'subsystem == "com.adappt.BabyTracker" && category == "Performance"' --info
/// or in Xcode, filter the console on `[Perf]`.
public enum PerfLog {
    public static let subsystem = "com.adappt.BabyTracker"

    public static let logger = Logger(subsystem: subsystem, category: "Performance")
    public static let signposter = OSSignposter(subsystem: subsystem, category: "Performance")

    /// Process-lifetime call counters keyed by label. A fresh launch resets them,
    /// which is what we want: the delta across a single `refresh` reveals how many
    /// times a method (e.g. `loadTimeline`) was invoked during that refresh.
    private static let counters = OSAllocatedUnfairLock(initialState: [String: Int]())

    /// Increments and returns the running total for `label`.
    @discardableResult
    public static func increment(_ label: String) -> Int {
        counters.withLock { store in
            let next = (store[label] ?? 0) + 1
            store[label] = next
            return next
        }
    }

    /// Current running total for `label` without mutating it. Read it before and
    /// after a span to log how many calls happened inside that span.
    public static func total(_ label: String) -> Int {
        counters.withLock { $0[label] ?? 0 }
    }

    /// Emit a one-off, stable, public log line (no timing).
    public static func event(_ message: String) {
        logger.info("[Perf] \(message, privacy: .public)")
    }

    /// Monotonic timestamp token (nanoseconds) for manual `defer`-based timing,
    /// so call sites don't need to import Dispatch.
    public static func now() -> UInt64 {
        DispatchTime.now().uptimeNanoseconds
    }

    /// Milliseconds elapsed since a token returned by `now()`.
    public static func elapsedMs(since start: UInt64) -> Double {
        Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
    }

    /// Time a synchronous block, emit a signpost interval and a `[Perf]` line with
    /// elapsed milliseconds. Returns the block's value.
    @discardableResult
    public static func measure<T>(_ label: String, _ body: () throws -> T) rethrows -> T {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("span", id: id, "\(label)")
        let start = DispatchTime.now().uptimeNanoseconds
        defer {
            let elapsedMs = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
            signposter.endInterval("span", state)
            logger.info("[Perf] \(label, privacy: .public) took \(elapsedMs, format: .fixed(precision: 2), privacy: .public) ms")
        }
        return try body()
    }

    /// Async variant of `measure`.
    @discardableResult
    public static func measureAsync<T>(_ label: String, _ body: () async throws -> T) async rethrows -> T {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("span", id: id, "\(label)")
        let start = DispatchTime.now().uptimeNanoseconds
        defer {
            let elapsedMs = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
            signposter.endInterval("span", state)
            logger.info("[Perf] \(label, privacy: .public) took \(elapsedMs, format: .fixed(precision: 2), privacy: .public) ms")
        }
        return try await body()
    }

    /// Convenience for the very common "this method was called; here's its running
    /// total" marker. Use a stable `label` so before/after diffs line up.
    public static func tick(_ label: String) {
        let count = increment(label)
        logger.info("[Perf] call \(label, privacy: .public) #\(count, privacy: .public)")
    }
}
