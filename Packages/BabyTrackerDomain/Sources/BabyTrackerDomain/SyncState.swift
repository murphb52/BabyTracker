import Foundation

public enum SyncState: String, Equatable, Sendable {
    case upToDate
    case pendingSync
    case syncing
    case failed
}
