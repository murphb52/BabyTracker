import Foundation

public struct EventMetadata: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let childID: UUID
    public var occurredAt: Date
    public let createdAt: Date
    public let createdBy: UUID
    public var updatedAt: Date
    public var updatedBy: UUID
    public var notes: String
    public var isDeleted: Bool
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        childID: UUID,
        occurredAt: Date,
        createdAt: Date = Date(),
        createdBy: UUID,
        updatedAt: Date? = nil,
        updatedBy: UUID? = nil,
        notes: String = "",
        isDeleted: Bool = false,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.childID = childID
        self.occurredAt = occurredAt
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.updatedAt = updatedAt ?? createdAt
        self.updatedBy = updatedBy ?? createdBy
        self.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
    }

    public mutating func markUpdated(
        at updatedAt: Date = Date(),
        by updatedBy: UUID
    ) {
        self.updatedAt = updatedAt
        self.updatedBy = updatedBy
    }

    public mutating func markDeleted(
        at deletedAt: Date = Date(),
        by deletedBy: UUID
    ) {
        isDeleted = true
        self.deletedAt = deletedAt
        updatedAt = deletedAt
        updatedBy = deletedBy
    }

    public mutating func restoreDeleted(
        at restoredAt: Date = Date(),
        by restoredBy: UUID
    ) {
        isDeleted = false
        deletedAt = nil
        updatedAt = restoredAt
        updatedBy = restoredBy
    }
}
