import Foundation

public struct BreastFeedEvent: Equatable, Identifiable, Sendable {
    public var metadata: EventMetadata
    public var side: BreastSide?
    public var startedAt: Date
    public var endedAt: Date?
    public var leftDurationSeconds: Int?
    public var rightDurationSeconds: Int?

    public var id: UUID {
        metadata.id
    }

    public init(
        metadata: EventMetadata,
        side: BreastSide?,
        startedAt: Date,
        endedAt: Date?,
        leftDurationSeconds: Int? = nil,
        rightDurationSeconds: Int? = nil
    ) throws {
        if let endedAt, endedAt <= startedAt {
            throw BabyEventError.invalidDateRange
        }

        self.metadata = metadata
        self.side = side
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.leftDurationSeconds = leftDurationSeconds
        self.rightDurationSeconds = rightDurationSeconds
    }

    public func updating(
        durationMinutes: Int,
        endTime: Date,
        side: BreastSide?,
        leftDurationSeconds: Int? = nil,
        rightDurationSeconds: Int? = nil,
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
            endedAt: endTime,
            leftDurationSeconds: leftDurationSeconds,
            rightDurationSeconds: rightDurationSeconds
        )
    }
}
