import Foundation

/// Finds the most recent non-deleted event in a category. An in-progress
/// sleep counts as the latest sleep.
@MainActor
public struct FetchLastEventUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let category: EventSummaryCategory

        public init(childID: UUID, category: EventSummaryCategory) {
            self.childID = childID
            self.category = category
        }
    }

    private let eventRepository: any EventRepository

    public init(eventRepository: any EventRepository) {
        self.eventRepository = eventRepository
    }

    public func execute(_ input: Input) throws -> BabyEvent? {
        try eventRepository
            .loadTimeline(for: input.childID, includingDeleted: false)
            .filter { !$0.metadata.isDeleted && input.category.includes($0) }
            .max { $0.metadata.occurredAt < $1.metadata.occurredAt }
    }
}
