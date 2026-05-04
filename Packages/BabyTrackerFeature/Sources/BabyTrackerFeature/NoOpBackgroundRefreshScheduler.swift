import Foundation

@MainActor
public final class NoOpBackgroundRefreshScheduler: BackgroundRefreshScheduling {
    public private(set) var registeredHandler: (() async -> Bool)?
    public private(set) var scheduleNextCallCount = 0

    public init() {}

    public func registerLaunchHandler(_ handler: @escaping () async -> Bool) {
        registeredHandler = handler
    }

    public func scheduleNext() {
        scheduleNextCallCount += 1
    }
}
