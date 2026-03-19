import Foundation

public struct Child: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var birthDate: Date?
    public let createdAt: Date
    public let createdBy: UUID
    public var isArchived: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date? = nil,
        createdAt: Date = Date(),
        createdBy: UUID,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.isArchived = isArchived
    }
}
