import Foundation

public enum SyncBannerState: Equatable, Sendable {
    case syncing
    case pendingSync(String)
    case syncUnavailable(String)
    case lastSyncFailed(String)

    public var message: String {
        switch self {
        case .syncing:
            "Syncing with iCloud…"
        case let .pendingSync(message):
            message
        case let .syncUnavailable(message):
            message
        case let .lastSyncFailed(message):
            message
        }
    }
}
