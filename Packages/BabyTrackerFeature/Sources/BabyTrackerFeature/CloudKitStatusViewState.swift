import BabyTrackerDomain
import Foundation

public struct CloudKitStatusViewState: Equatable, Sendable {
    public let state: SyncState
    public let pendingRecordCount: Int
    public let lastSyncAt: Date?
    public let detailMessage: String?
    public let isAccountUnavailable: Bool

    public init(summary: SyncStatusSummary) {
        self.state = summary.state
        self.pendingRecordCount = summary.pendingRecordCount
        self.lastSyncAt = summary.lastSyncAt
        let detailMessage = Self.detailMessage(for: summary)
        self.detailMessage = detailMessage
        self.isAccountUnavailable = Self.isAccountUnavailableMessage(detailMessage)
    }

    public var statusTitle: String {
        switch state {
        case .upToDate:
            return "Up to date"
        case .pendingSync:
            return "Waiting to sync"
        case .syncing:
            return "Syncing now"
        case .failed:
            if isAccountUnavailable {
                return "Sync unavailable"
            }

            return "Sync failed"
        }
    }

    public var backupTitle: String {
        if lastSyncAt != nil {
            return state == .failed ? "Last backup available" : "Backed up to iCloud"
        }

        return "Not backed up yet"
    }

    public var pendingChangesTitle: String? {
        guard pendingRecordCount > 0 else {
            return nil
        }

        return pendingRecordCount == 1 ? "1 change" : "\(pendingRecordCount) changes"
    }

    public var syncSettingsBannerTitle: String? {
        guard isAccountUnavailable else {
            return nil
        }

        return "iCloud backup is unavailable"
    }

    public var syncSettingsBannerMessage: String? {
        guard isAccountUnavailable else {
            return nil
        }

        return "Baby Tracker is still saving data on this device. Sign in to iCloud in Settings to resume backups and sharing."
    }

    private static func detailMessage(for summary: SyncStatusSummary) -> String? {
        switch summary.state {
        case .upToDate:
            return nil
        case .syncing:
            return "Uploading your latest changes now."
        case .pendingSync:
            if summary.pendingRecordCount == 0 {
                return "Changes saved locally. Sync will resume automatically."
            }

            return summary.pendingRecordCount == 1 ?
                "1 change is waiting to sync." :
                "\(summary.pendingRecordCount) changes are waiting to sync."
        case .failed:
            return summary.lastErrorDescription ?? "Last sync failed. Local data is still available."
        }
    }

    public static func isAccountUnavailableMessage(_ message: String?) -> Bool {
        guard let message else {
            return false
        }

        return message.localizedCaseInsensitiveContains("unavailable") ||
            message.localizedCaseInsensitiveContains("sign in to iCloud")
    }
}
