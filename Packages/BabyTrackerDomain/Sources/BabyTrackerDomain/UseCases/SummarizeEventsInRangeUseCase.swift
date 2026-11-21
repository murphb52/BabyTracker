import Foundation

/// Totals one category of events over a relative period.
///
/// Events are placed by `occurredAt` and durations use whole minutes with a
/// one-minute floor, the same rules as the Summary tab, so the assistant's
/// numbers match what caregivers see there.
@MainActor
public struct SummarizeEventsInRangeUseCase: UseCase {
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

    public func execute(_ input: Input) throws -> EventRangeSummary {
        let interval = input.period.interval(now: input.now, calendar: calendar)
        let events = try eventRepository
            .loadTimeline(for: input.childID, includingDeleted: false)
            .filter { event in
                !event.metadata.isDeleted &&
                    input.category.includes(event) &&
                    interval.containsHalfOpen(event.metadata.occurredAt)
            }

        let bottles = events.compactMap(\.bottleFeedValue)
        let breastFeeds = events.compactMap(\.breastFeedValue)
        let sleepMinutes = events.compactMap(\.sleepValue).compactMap(Self.completedSleepMinutes)

        return EventRangeSummary(
            category: input.category,
            period: input.period,
            eventCount: events.count,
            bottleFeedCount: bottles.count,
            bottleTotalMilliliters: bottles.reduce(0) { $0 + $1.amountMilliliters },
            breastFeedCount: breastFeeds.count,
            breastFeedTotalMinutes: breastFeeds.reduce(0) { $0 + Self.minutes(from: $1.startedAt, to: $1.endedAt) },
            completedSleepCount: sleepMinutes.count,
            totalSleepMinutes: sleepMinutes.reduce(0, +),
            longestSleepMinutes: sleepMinutes.max(),
            nappyCountsByType: Self.nappyCounts(events),
            itemCountsByName: Self.itemCounts(events)
        )
    }

    private static func completedSleepMinutes(_ sleep: SleepEvent) -> Int? {
        guard let endedAt = sleep.endedAt else { return nil }
        return minutes(from: sleep.startedAt, to: endedAt)
    }

    private static func minutes(from start: Date, to end: Date) -> Int {
        max(1, Int(end.timeIntervalSince(start) / 60))
    }

    private static func nappyCounts(_ events: [BabyEvent]) -> [NappyType: Int] {
        var counts: [NappyType: Int] = [:]
        for event in events {
            guard case let .nappy(nappy) = event else { continue }
            counts[nappy.type, default: 0] += 1
        }
        return counts
    }

    private static func itemCounts(_ events: [BabyEvent]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for event in events {
            switch event {
            case let .food(food):
                counts[food.foodName, default: 0] += 1
            case let .medication(medication):
                counts[medication.medicineName, default: 0] += 1
            case .bath, .breastFeed, .bottleFeed, .sleep, .nappy:
                continue
            }
        }
        return counts
    }
}

private extension BabyEvent {
    var bottleFeedValue: BottleFeedEvent? {
        guard case let .bottleFeed(feed) = self else { return nil }
        return feed
    }

    var breastFeedValue: BreastFeedEvent? {
        guard case let .breastFeed(feed) = self else { return nil }
        return feed
    }

    var sleepValue: SleepEvent? {
        guard case let .sleep(sleep) = self else { return nil }
        return sleep
    }
}
