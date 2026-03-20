import Foundation

public struct NappyEvent: Equatable, Identifiable, Sendable {
    public var metadata: EventMetadata
    public var type: NappyType
    public var intensity: NappyIntensity?
    public var pooColor: PooColor?

    public var id: UUID {
        metadata.id
    }

    public init(
        metadata: EventMetadata,
        type: NappyType,
        intensity: NappyIntensity? = nil,
        pooColor: PooColor? = nil
    ) throws {
        _ = try NappyEntry(
            type: type,
            intensity: intensity,
            pooColor: pooColor
        )

        self.metadata = metadata
        self.type = type
        self.intensity = intensity
        self.pooColor = pooColor
    }

    public func updating(
        type: NappyType,
        occurredAt: Date,
        intensity: NappyIntensity?,
        pooColor: PooColor?,
        updatedAt: Date = Date(),
        updatedBy: UUID
    ) throws -> NappyEvent {
        var metadata = metadata
        metadata.occurredAt = occurredAt
        metadata.markUpdated(at: updatedAt, by: updatedBy)

        return try NappyEvent(
            metadata: metadata,
            type: type,
            intensity: intensity,
            pooColor: pooColor
        )
    }
}
