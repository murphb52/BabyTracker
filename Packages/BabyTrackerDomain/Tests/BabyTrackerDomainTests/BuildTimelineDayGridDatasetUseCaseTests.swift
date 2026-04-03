import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct BuildTimelineDayGridDatasetUseCaseTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test
    func createsFourColumnsForEveryDay() throws {
        let day = Date(timeIntervalSince1970: 1_700_000_000)

        let dataset = BuildTimelineDayGridDatasetUseCase().execute(
            events: [],
            day: day,
            calendar: calendar
        )

        #expect(dataset.columns.map(\.kind) == [.sleep, .nappy, .bottleFeed, .breastFeed])
    }

    @Test
    func bottleFeedOccupiesOneSlot() throws {
        let day = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let bottle = try makeBottleFeed(atHour: 10, minute: 10, day: day)

        let dataset = BuildTimelineDayGridDatasetUseCase().execute(
            events: [.bottleFeed(bottle)],
            day: day,
            calendar: calendar
        )

        let placement = try #require(dataset.columns.first(where: { $0.kind == .bottleFeed })?.placements.first)
        #expect(placement.startSlotIndex == 40)
        #expect(placement.endSlotIndex == 41)
    }

    @Test
    func nappyOccupiesOneSlot() throws {
        let day = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let nappy = try makeNappy(atHour: 6, minute: 59, day: day)

        let dataset = BuildTimelineDayGridDatasetUseCase().execute(
            events: [.nappy(nappy)],
            day: day,
            calendar: calendar
        )

        let placement = try #require(dataset.columns.first(where: { $0.kind == .nappy })?.placements.first)
        #expect(placement.startSlotIndex == 27)
        #expect(placement.endSlotIndex == 28)
    }

    @Test
    func breastFeedRoundsToSlotBoundaries() throws {
        let day = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let feed = try makeBreastFeed(
            startHour: 8,
            startMinute: 7,
            endHour: 8,
            endMinute: 52,
            day: day
        )

        let dataset = BuildTimelineDayGridDatasetUseCase().execute(
            events: [.breastFeed(feed)],
            day: day,
            calendar: calendar
        )

        let placement = try #require(dataset.columns.first(where: { $0.kind == .breastFeed })?.placements.first)
        #expect(placement.startSlotIndex == 32)
        #expect(placement.endSlotIndex == 36)
    }

    @Test
    func completedSleepSpanningMidnightIsClippedToSelectedDay() throws {
        let day = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let sleepStart = try #require(calendar.date(byAdding: .minute, value: -30, to: day))
        let sleepEnd = try #require(calendar.date(byAdding: .minute, value: 30, to: day))
        let sleep = try makeSleep(startedAt: sleepStart, endedAt: sleepEnd, occurredAt: sleepEnd)

        let dataset = BuildTimelineDayGridDatasetUseCase().execute(
            events: [.sleep(sleep)],
            day: day,
            calendar: calendar
        )

        let placement = try #require(dataset.columns.first(where: { $0.kind == .sleep })?.placements.first)
        #expect(placement.startSlotIndex == 0)
        #expect(placement.endSlotIndex == 2)
    }

    @Test
    func activeSleepEndsAtNowAndIsClippedToSelectedDay() throws {
        let day = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let start = try #require(calendar.date(byAdding: .hour, value: 23, to: day))
        let now = try #require(calendar.date(byAdding: .minute, value: 45, to: start))
        let sleep = try makeSleep(startedAt: start, endedAt: nil, occurredAt: start)

        let dataset = BuildTimelineDayGridDatasetUseCase().execute(
            events: [.sleep(sleep)],
            day: day,
            calendar: calendar,
            now: now
        )

        let placement = try #require(dataset.columns.first(where: { $0.kind == .sleep })?.placements.first)
        #expect(placement.startSlotIndex == 92)
        #expect(placement.endSlotIndex == 95)
    }

    @Test
    func sameColumnOverlapsMergeIntoOnePlacement() throws {
        let day = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let first = try makeSleep(
            startedAt: date(day: day, hour: 1, minute: 0),
            endedAt: date(day: day, hour: 2, minute: 0),
            occurredAt: date(day: day, hour: 2, minute: 0)
        )
        let second = try makeSleep(
            startedAt: date(day: day, hour: 1, minute: 30),
            endedAt: date(day: day, hour: 3, minute: 0),
            occurredAt: date(day: day, hour: 3, minute: 0)
        )

        let dataset = BuildTimelineDayGridDatasetUseCase().execute(
            events: [.sleep(first), .sleep(second)],
            day: day,
            calendar: calendar
        )

        let placements = try #require(dataset.columns.first(where: { $0.kind == .sleep })?.placements)
        #expect(placements.count == 1)
        #expect(placements[0].eventIDs == [first.id, second.id])
        #expect(placements[0].startSlotIndex == 4)
        #expect(placements[0].endSlotIndex == 12)
    }

    @Test
    func sameColumnAdjacentPlacementsMergeWhenTouching() throws {
        let day = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let first = try makeSleep(
            startedAt: date(day: day, hour: 4, minute: 0),
            endedAt: date(day: day, hour: 4, minute: 30),
            occurredAt: date(day: day, hour: 4, minute: 30)
        )
        let second = try makeSleep(
            startedAt: date(day: day, hour: 4, minute: 30),
            endedAt: date(day: day, hour: 5, minute: 0),
            occurredAt: date(day: day, hour: 5, minute: 0)
        )

        let dataset = BuildTimelineDayGridDatasetUseCase().execute(
            events: [.sleep(first), .sleep(second)],
            day: day,
            calendar: calendar
        )

        let placements = try #require(dataset.columns.first(where: { $0.kind == .sleep })?.placements)
        #expect(placements.count == 1)
        #expect(placements[0].eventIDs == [first.id, second.id])
        #expect(placements[0].startSlotIndex == 16)
        #expect(placements[0].endSlotIndex == 20)
    }

    @Test
    func differentColumnsRemainSeparateAtSameTime() throws {
        let day = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let sleep = try makeSleep(
            startedAt: date(day: day, hour: 9, minute: 0),
            endedAt: date(day: day, hour: 10, minute: 0),
            occurredAt: date(day: day, hour: 10, minute: 0)
        )
        let bottle = try makeBottleFeed(atHour: 9, minute: 0, day: day)

        let dataset = BuildTimelineDayGridDatasetUseCase().execute(
            events: [.sleep(sleep), .bottleFeed(bottle)],
            day: day,
            calendar: calendar
        )

        #expect(dataset.columns.first(where: { $0.kind == .sleep })?.placements.count == 1)
        #expect(dataset.columns.first(where: { $0.kind == .bottleFeed })?.placements.count == 1)
    }

    @Test
    func placementsAreSortedByStartSlot() throws {
        let day = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let later = try makeBottleFeed(atHour: 12, minute: 0, day: day)
        let earlier = try makeBottleFeed(atHour: 8, minute: 0, day: day)

        let dataset = BuildTimelineDayGridDatasetUseCase().execute(
            events: [.bottleFeed(later), .bottleFeed(earlier)],
            day: day,
            calendar: calendar
        )

        let placements = try #require(dataset.columns.first(where: { $0.kind == .bottleFeed })?.placements)
        #expect(placements.map(\.eventIDs) == [[earlier.id], [later.id]])
    }

    private func makeBottleFeed(atHour hour: Int, minute: Int, day: Date) throws -> BottleFeedEvent {
        let occurredAt = date(day: day, hour: hour, minute: minute)
        return try BottleFeedEvent(
            metadata: EventMetadata(childID: UUID(), occurredAt: occurredAt, createdBy: UUID()),
            amountMilliliters: 120
        )
    }

    private func makeNappy(atHour hour: Int, minute: Int, day: Date) throws -> NappyEvent {
        let occurredAt = date(day: day, hour: hour, minute: minute)
        return try NappyEvent(
            metadata: EventMetadata(childID: UUID(), occurredAt: occurredAt, createdBy: UUID()),
            type: .wee
        )
    }

    private func makeBreastFeed(
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        day: Date
    ) throws -> BreastFeedEvent {
        let startedAt = date(day: day, hour: startHour, minute: startMinute)
        let endedAt = date(day: day, hour: endHour, minute: endMinute)
        return try BreastFeedEvent(
            metadata: EventMetadata(childID: UUID(), occurredAt: endedAt, createdBy: UUID()),
            side: nil,
            startedAt: startedAt,
            endedAt: endedAt
        )
    }

    private func makeSleep(
        startedAt: Date,
        endedAt: Date?,
        occurredAt: Date
    ) throws -> SleepEvent {
        try SleepEvent(
            metadata: EventMetadata(childID: UUID(), occurredAt: occurredAt, createdBy: UUID()),
            startedAt: startedAt,
            endedAt: endedAt
        )
    }

    private func date(day: Date, hour: Int, minute: Int) -> Date {
        calendar.date(byAdding: .minute, value: (hour * 60) + minute, to: day)!
    }
}
