import Foundation

public struct UserIdentity: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var displayName: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        displayName: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.createdAt = createdAt
    }
}
