import Foundation

public struct PendingShareInviteViewState: Equatable, Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let statusLabel: String

    public init(
        id: String,
        displayName: String,
        statusLabel: String
    ) {
        self.id = id
        self.displayName = displayName
        self.statusLabel = statusLabel
    }
}
