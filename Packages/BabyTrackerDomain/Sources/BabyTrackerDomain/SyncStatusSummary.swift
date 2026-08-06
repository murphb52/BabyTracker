import Foundation

public struct SyncStatusSummary: Equatable, Sendable {
    public let state: SyncState
    public let pendingRecordCount: Int
    public let lastSyncAt: Date?
    public let lastErrorDescription: String?

    /// Whether the refresh that produced this summary actually applied remote
    /// records locally. Background wake-ups use this to report an accurate
    /// `UIBackgroundFetchResult` and to skip reloading UI state that cannot
    /// have changed.
    public let didApplyRemoteChanges: Bool

    public init(
        state: SyncState = .upToDate,
        pendingRecordCount: Int = 0,
        lastSyncAt: Date? = nil,
        lastErrorDescription: String? = nil,
        didApplyRemoteChanges: Bool = false
    ) {
        self.state = state
        self.pendingRecordCount = pendingRecordCount
        self.lastSyncAt = lastSyncAt
        self.lastErrorDescription = lastErrorDescription
        self.didApplyRemoteChanges = didApplyRemoteChanges
    }
}
