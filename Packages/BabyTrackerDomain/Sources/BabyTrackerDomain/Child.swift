import Foundation

public struct Child: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var birthDate: Date?
    public let createdAt: Date
    public let createdBy: UUID
    public var isArchived: Bool
    public var imageData: Data?
    public var preferredFeedVolumeUnit: FeedVolumeUnit

    public init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date? = nil,
        createdAt: Date = Date(),
        createdBy: UUID,
        isArchived: Bool = false,
        imageData: Data? = nil,
        preferredFeedVolumeUnit: FeedVolumeUnit = .milliliters
    ) throws {
        let normalizedName = name.trimmedForProfileField()
        guard !normalizedName.isEmpty else {
            throw ChildProfileValidationError.emptyChildName
        }

        self.id = id
        self.name = normalizedName
        self.birthDate = birthDate
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.isArchived = isArchived
        self.imageData = imageData
        self.preferredFeedVolumeUnit = preferredFeedVolumeUnit
    }

    public func updating(
        name: String,
        birthDate: Date?,
        imageData: Data? = nil,
        preferredFeedVolumeUnit: FeedVolumeUnit
    ) throws -> Child {
        try Child(
            id: id,
            name: name,
            birthDate: birthDate,
            createdAt: createdAt,
            createdBy: createdBy,
            isArchived: isArchived,
            imageData: imageData,
            preferredFeedVolumeUnit: preferredFeedVolumeUnit
        )
    }
}
