import Foundation

public struct NappyEvent: Equatable, Identifiable, Sendable {
    public var metadata: EventMetadata
    public var type: NappyType
    public var peeVolume: NappyVolume?
    public var pooVolume: NappyVolume?
    public var pooColor: PooColor?

    public var id: UUID {
        metadata.id
    }

    public init(
        metadata: EventMetadata,
        type: NappyType,
        peeVolume: NappyVolume? = nil,
        pooVolume: NappyVolume? = nil,
        pooColor: PooColor? = nil
    ) throws {
        _ = try NappyEntry(
            type: type,
            peeVolume: peeVolume,
            pooVolume: pooVolume,
            pooColor: pooColor
        )

        self.metadata = metadata
        self.type = type
        self.peeVolume = peeVolume
        self.pooVolume = pooVolume
        self.pooColor = pooColor
    }

    public func updating(
        type: NappyType,
        occurredAt: Date,
        peeVolume: NappyVolume?,
        pooVolume: NappyVolume?,
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
            peeVolume: peeVolume,
            pooVolume: pooVolume,
            pooColor: pooColor
        )
    }
}
