import Foundation

public enum BabyEvent: Equatable, Identifiable, Sendable {
    case bath(BathEvent)
    case breastFeed(BreastFeedEvent)
    case bottleFeed(BottleFeedEvent)
    case sleep(SleepEvent)
    case nappy(NappyEvent)
    case medication(MedicationEvent)

    public var id: UUID {
        metadata.id
    }

    public var metadata: EventMetadata {
        switch self {
        case let .bath(event):
            event.metadata
        case let .breastFeed(event):
            event.metadata
        case let .bottleFeed(event):
            event.metadata
        case let .sleep(event):
            event.metadata
        case let .nappy(event):
            event.metadata
        case let .medication(event):
            event.metadata
        }
    }

    public var kind: BabyEventKind {
        switch self {
        case .bath:
            .bath
        case .breastFeed:
            .breastFeed
        case .bottleFeed:
            .bottleFeed
        case .sleep:
            .sleep
        case .nappy:
            .nappy
        case .medication:
            .medication
        }
    }

    /// Whether this event should be considered part of the given day.
    ///
    /// Instant events (bath/bottle feed/nappy/medication) use `occurredAt`.
    /// Sessions with a duration (sleep, breast feed) overlap a day if any
    /// part of the session falls within it, so a session spanning midnight
    /// counts on both days. An active sleep session (nil `endedAt`) is
    /// treated as still ongoing.
    public func overlaps(startOfDay: Date, endOfDay: Date) -> Bool {
        switch self {
        case let .sleep(sleep):
            let end = sleep.endedAt ?? Date.distantFuture
            return sleep.startedAt < endOfDay && end > startOfDay
        case let .breastFeed(feed):
            return feed.startedAt < endOfDay && feed.endedAt > startOfDay
        case .bath, .bottleFeed, .nappy, .medication:
            return metadata.occurredAt >= startOfDay && metadata.occurredAt < endOfDay
        }
    }
}
