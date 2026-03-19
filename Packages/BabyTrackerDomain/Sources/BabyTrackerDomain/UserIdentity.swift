import Foundation

public struct UserIdentity: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var displayName: String
    public let createdAt: Date
    public var cloudKitUserRecordName: String?

    public init(
        id: UUID = UUID(),
        displayName: String,
        createdAt: Date = Date(),
        cloudKitUserRecordName: String? = nil
    ) throws {
        let normalizedDisplayName = displayName.trimmedForProfileField()
        guard !normalizedDisplayName.isEmpty else {
            throw ChildProfileValidationError.emptyCaregiverName
        }

        self.id = id
        self.displayName = normalizedDisplayName
        self.createdAt = createdAt
        self.cloudKitUserRecordName = cloudKitUserRecordName
    }

    public func updating(
        displayName: String,
        cloudKitUserRecordName: String?
    ) throws -> UserIdentity {
        try UserIdentity(
            id: id,
            displayName: displayName,
            createdAt: createdAt,
            cloudKitUserRecordName: cloudKitUserRecordName
        )
    }
}
