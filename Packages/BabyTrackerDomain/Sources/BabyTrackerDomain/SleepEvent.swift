import Foundation

public struct SleepEvent: Equatable, Identifiable, Sendable {
    public var metadata: EventMetadata
    public var startedAt: Date
    public var endedAt: Date?

    public var id: UUID {
        metadata.id
    }

    public init(
        metadata: EventMetadata,
        startedAt: Date,
        endedAt: Date? = nil
    ) throws {
        if let endedAt, endedAt < startedAt {
            throw BabyEventError.invalidDateRange
        }

        self.metadata = metadata
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}
