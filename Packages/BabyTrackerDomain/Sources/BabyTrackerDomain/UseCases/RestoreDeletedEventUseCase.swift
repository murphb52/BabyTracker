import Foundation

@MainActor
public struct RestoreDeletedEventUseCase: UseCase {
    public struct Input {
        public let event: BabyEvent
        public let restoredBy: UUID

        public init(event: BabyEvent, restoredBy: UUID) {
            self.event = event
            self.restoredBy = restoredBy
        }
    }

    private let eventRepository: any EventRepository

    public init(eventRepository: any EventRepository) {
        self.eventRepository = eventRepository
    }

    public func execute(_ input: Input) throws -> BabyEvent {
        let restoredEvent = restoreDeleted(input.event, by: input.restoredBy)
        try eventRepository.saveEvent(restoredEvent)
        return restoredEvent
    }

    private func restoreDeleted(_ event: BabyEvent, by userID: UUID) -> BabyEvent {
        switch event {
        case var .breastFeed(feed):
            feed.metadata.restoreDeleted(by: userID)
            return .breastFeed(feed)
        case var .bottleFeed(feed):
            feed.metadata.restoreDeleted(by: userID)
            return .bottleFeed(feed)
        case var .sleep(feed):
            feed.metadata.restoreDeleted(by: userID)
            return .sleep(feed)
        case var .nappy(feed):
            feed.metadata.restoreDeleted(by: userID)
            return .nappy(feed)
        }
    }
}
