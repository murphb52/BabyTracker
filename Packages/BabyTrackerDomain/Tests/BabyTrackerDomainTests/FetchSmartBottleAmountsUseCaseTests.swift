import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct FetchSmartBottleAmountsUseCaseTests {
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    @Test
    func returnsEmptyWhenNoHistory() throws {
        let repo = StubBottleEventRepository(events: [])
        let result = try FetchSmartBottleAmountsUseCase(eventRepository: repo, calendar: calendar)
            .execute(.init(childID: UUID(), referenceTime: date(hour: 19, minutesAgo: 0)))
        #expect(result.isEmpty)
    }

    @Test
    func returnsTopAmountFromMatchingWindow() throws {
        let childID = UUID()
        let ref = date(hour: 19, minutesAgo: 0)
        let events: [BabyEvent] = [
            .bottleFeed(try makeBottleFeed(childID: childID, amount: 120, daysAgo: 1, hour: 19)),
            .bottleFeed(try makeBottleFeed(childID: childID, amount: 120, daysAgo: 2, hour: 19)),
            .bottleFeed(try makeBottleFeed(childID: childID, amount: 90, daysAgo: 3, hour: 19)),
        ]
        let repo = StubBottleEventRepository(events: events)
        let result = try FetchSmartBottleAmountsUseCase(eventRepository: repo, calendar: calendar)
            .execute(.init(childID: childID, referenceTime: ref))
        #expect(result.first == 120)
    }

    @Test
    func returnsAtMostTwoSuggestions() throws {
        let childID = UUID()
        let ref = date(hour: 10, minutesAgo: 0)
        let events: [BabyEvent] = [
            .bottleFeed(try makeBottleFeed(childID: childID, amount: 60, daysAgo: 1, hour: 10)),
            .bottleFeed(try makeBottleFeed(childID: childID, amount: 90, daysAgo: 2, hour: 10)),
            .bottleFeed(try makeBottleFeed(childID: childID, amount: 120, daysAgo: 3, hour: 10)),
        ]
        let repo = StubBottleEventRepository(events: events)
        let result = try FetchSmartBottleAmountsUseCase(eventRepository: repo, calendar: calendar)
            .execute(.init(childID: childID, referenceTime: ref))
        #expect(result.count <= 2)
    }

    @Test
    func ignoresEventsOutsideTimeWindow() throws {
        let childID = UUID()
        let ref = date(hour: 14, minutesAgo: 0)
        let events: [BabyEvent] = [
            // 6 hours away — outside the ±2h window
            .bottleFeed(try makeBottleFeed(childID: childID, amount: 150, daysAgo: 1, hour: 8)),
        ]
        let repo = StubBottleEventRepository(events: events)
        let result = try FetchSmartBottleAmountsUseCase(eventRepository: repo, calendar: calendar)
            .execute(.init(childID: childID, referenceTime: ref))
        #expect(result.isEmpty)
    }

    @Test
    func ignoresEventsOlderThanSevenDays() throws {
        let childID = UUID()
        let ref = date(hour: 8, minutesAgo: 0)
        let events: [BabyEvent] = [
            .bottleFeed(try makeBottleFeed(childID: childID, amount: 120, daysAgo: 8, hour: 8)),
        ]
        let repo = StubBottleEventRepository(events: events)
        let result = try FetchSmartBottleAmountsUseCase(eventRepository: repo, calendar: calendar)
            .execute(.init(childID: childID, referenceTime: ref))
        #expect(result.isEmpty)
    }

    @Test
    func includesEventsWithinWindowEdge() throws {
        let childID = UUID()
        let ref = date(hour: 12, minutesAgo: 0)
        // Exactly 2 hours before — should be included
        let events: [BabyEvent] = [
            .bottleFeed(try makeBottleFeed(childID: childID, amount: 100, daysAgo: 1, hour: 10)),
        ]
        let repo = StubBottleEventRepository(events: events)
        let result = try FetchSmartBottleAmountsUseCase(eventRepository: repo, calendar: calendar)
            .execute(.init(childID: childID, referenceTime: ref))
        #expect(result.contains(100))
    }

    // MARK: - Helpers

    private func date(hour: Int, minutesAgo: Int) -> Date {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = 0
        components.second = 0
        let base = calendar.date(from: components)!
        return base.addingTimeInterval(TimeInterval(-minutesAgo * 60))
    }

    private func makeBottleFeed(childID: UUID, amount: Int, daysAgo: Int, hour: Int) throws -> BottleFeedEvent {
        let ref = date(hour: hour, minutesAgo: 0)
        let occurredAt = calendar.date(byAdding: .day, value: -daysAgo, to: ref)!
        return try BottleFeedEvent(
            metadata: EventMetadata(childID: childID, occurredAt: occurredAt, createdBy: UUID()),
            amountMilliliters: amount
        )
    }
}

@MainActor
private final class StubBottleEventRepository: EventRepository {
    private let events: [BabyEvent]

    init(events: [BabyEvent]) {
        self.events = events
    }

    func saveEvent(_ event: BabyEvent) throws {}
    func loadEvent(id: UUID) throws -> BabyEvent? { nil }
    func loadTimeline(for childID: UUID, includingDeleted: Bool) throws -> [BabyEvent] { events }
    func loadEvents(for childID: UUID, on day: Date, calendar: Calendar, includingDeleted: Bool) throws -> [BabyEvent] { [] }
    func loadActiveSleepEvent(for childID: UUID) throws -> SleepEvent? { nil }
    func softDeleteEvent(id: UUID, deletedAt: Date, deletedBy: UUID) throws {}
}
