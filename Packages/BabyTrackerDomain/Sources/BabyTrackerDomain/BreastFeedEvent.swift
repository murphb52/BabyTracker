import Foundation

public struct BreastFeedEvent: Equatable, Identifiable, Sendable {
    public var metadata: EventMetadata
    public var side: BreastSide?
    public var startedAt: Date
    public var endedAt: Date

    public var id: UUID {
        metadata.id
    }

    public init(
        metadata: EventMetadata,
        side: BreastSide?,
        startedAt: Date,
        endedAt: Date
    ) throws {
        guard endedAt > startedAt else {
            throw BabyEventError.invalidDateRange
        }

        self.metadata = metadata
        self.side = side
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    public func updating(
        durationMinutes: Int,
        endTime: Date,
        side: BreastSide?,
        updatedAt: Date = Date(),
        updatedBy: UUID
    ) throws -> BreastFeedEvent {
        let startedAt = endTime.addingTimeInterval(TimeInterval(durationMinutes * -60))

        var metadata = metadata
        metadata.occurredAt = endTime
        metadata.markUpdated(at: updatedAt, by: updatedBy)

        return try BreastFeedEvent(
            metadata: metadata,
            side: side,
            startedAt: startedAt,
            endedAt: endTime
        )
    }
}
