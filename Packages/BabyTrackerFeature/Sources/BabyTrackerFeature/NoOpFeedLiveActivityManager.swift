import Foundation

@MainActor
public final class NoOpFeedLiveActivityManager: FeedLiveActivityManaging {
    public init() {}

    public var hasRunningActivity: Bool { false }

    public func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        _ = snapshot
    }

    public func currentDiagnostic() -> FeedLiveActivityDiagnostic {
        FeedLiveActivityDiagnostic(
            hasRunningActivity: false,
            activeActivityID: nil,
            runningActivityIDs: [],
            systemAuthorizationGranted: false,
            lastSyncSummary: "no-op manager"
        )
    }
}
