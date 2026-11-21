import Foundation

/// Counts which hour of the day a category of event tends to start in.
/// Sleep uses its start time (when the nap began). Everything else uses
/// `occurredAt`.
@MainActor
public struct FindDailyPatternUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let category: EventSummaryCategory
        public let period: RelativePeriod
        public let now: Date

        public init(childID: UUID, category: EventSummaryCategory, period: RelativePeriod, now: Date) {
            self.childID = childID
            self.category = category
            self.period = period
            self.now = now
        }
    }

    private let eventRepository: any EventRepository
    private let calendar: Calendar

    public init(eventRepository: any EventRepository, calendar: Calendar = .current) {
        self.eventRepository = eventRepository
        self.calendar = calendar
    }

    public func execute(_ input: Input) throws -> DailyPattern {
        let interval = input.period.interval(now: input.now, calendar: calendar)
        var countsByHour = Array(repeating: 0, count: 24)

        for event in try eventRepository.loadTimeline(for: input.childID, includingDeleted: false) {
            guard !event.metadata.isDeleted, input.category.includes(event) else { continue }
            let startTime = Self.startTime(of: event)
            guard interval.containsHalfOpen(startTime) else { continue }
            countsByHour[calendar.component(.hour, from: startTime)] += 1
        }

        return DailyPattern(category: input.category, period: input.period, countsByHour: countsByHour)
    }

    private static func startTime(of event: BabyEvent) -> Date {
        switch event {
        case let .sleep(sleep):
            sleep.startedAt
        case let .breastFeed(feed):
            feed.startedAt
        case .bath, .bottleFeed, .food, .nappy, .medication:
            event.metadata.occurredAt
        }
    }
}
