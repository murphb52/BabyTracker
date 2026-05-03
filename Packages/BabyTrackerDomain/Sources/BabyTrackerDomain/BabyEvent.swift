import Foundation

public enum BabyEvent: Equatable, Identifiable, Sendable {
    case bath(BathEvent)
    case breastFeed(BreastFeedEvent)
    case bottleFeed(BottleFeedEvent)
    case sleep(SleepEvent)
    case nappy(NappyEvent)

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
        }
    }
}
