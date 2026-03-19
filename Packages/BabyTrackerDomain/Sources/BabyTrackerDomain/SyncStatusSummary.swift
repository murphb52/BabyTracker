import Foundation

public struct SyncStatusSummary: Equatable, Sendable {
    public let state: SyncState
    public let pendingRecordCount: Int
    public let lastSyncAt: Date?
    public let lastErrorDescription: String?

    public init(
        state: SyncState = .upToDate,
        pendingRecordCount: Int = 0,
        lastSyncAt: Date? = nil,
        lastErrorDescription: String? = nil
    ) {
        self.state = state
        self.pendingRecordCount = pendingRecordCount
        self.lastSyncAt = lastSyncAt
        self.lastErrorDescription = lastErrorDescription
    }
}
