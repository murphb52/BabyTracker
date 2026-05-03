import Foundation

public struct BathEvent: Equatable, Identifiable, Sendable {
    public var metadata: EventMetadata
    public var usedShampoo: Bool
    public var usedSoap: Bool

    public var id: UUID {
        metadata.id
    }

    public init(
        metadata: EventMetadata,
        usedShampoo: Bool,
        usedSoap: Bool
    ) {
        self.metadata = metadata
        self.usedShampoo = usedShampoo
        self.usedSoap = usedSoap
    }

    public func updating(
        occurredAt: Date,
        usedShampoo: Bool,
        usedSoap: Bool,
        updatedAt: Date = Date(),
        updatedBy: UUID
    ) -> BathEvent {
        var metadata = metadata
        metadata.occurredAt = occurredAt
        metadata.markUpdated(at: updatedAt, by: updatedBy)

        return BathEvent(
            metadata: metadata,
            usedShampoo: usedShampoo,
            usedSoap: usedSoap
        )
    }
}
