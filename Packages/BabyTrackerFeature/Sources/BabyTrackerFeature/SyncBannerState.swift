import Foundation

public enum SyncBannerState: Equatable, Sendable {
    case syncing
    case synced
    case lastSyncFailed(String)

    public var accessibilityLabel: String {
        switch self {
        case .syncing:
            "Syncing with iCloud"
        case .synced:
            "iCloud sync complete"
        case let .lastSyncFailed(message):
            message
        }
    }
}
