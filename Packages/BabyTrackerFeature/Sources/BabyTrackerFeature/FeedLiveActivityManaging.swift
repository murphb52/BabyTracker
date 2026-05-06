import Foundation

/// Snapshot of the live-activity manager's current state, used by the in-app
/// debug reset button to log what the world looked like before tearing down.
public struct FeedLiveActivityDiagnostic: Sendable, Equatable {
    public let hasRunningActivity: Bool
    public let activeActivityID: String?
    public let runningActivityIDs: [String]
    public let systemAuthorizationGranted: Bool
    public let lastSyncSummary: String?

    public init(
        hasRunningActivity: Bool,
        activeActivityID: String?,
        runningActivityIDs: [String],
        systemAuthorizationGranted: Bool,
        lastSyncSummary: String?
    ) {
        self.hasRunningActivity = hasRunningActivity
        self.activeActivityID = activeActivityID
        self.runningActivityIDs = runningActivityIDs
        self.systemAuthorizationGranted = systemAuthorizationGranted
        self.lastSyncSummary = lastSyncSummary
    }
}

@MainActor
public protocol FeedLiveActivityManaging: AnyObject {
    var hasRunningActivity: Bool { get }
    func synchronize(with snapshot: FeedLiveActivitySnapshot?)
    func currentDiagnostic() -> FeedLiveActivityDiagnostic
}
