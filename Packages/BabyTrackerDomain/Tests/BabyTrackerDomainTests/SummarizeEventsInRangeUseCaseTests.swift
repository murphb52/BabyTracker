import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct SummarizeEventsInRangeUseCaseTests {
    private typealias Fixture = AssistantQueryFixtures

    @Test
    func totalsBottleAndBreastFeedsForToday() throws {
        let summary = try summarize(.feeds, .today, events: [
            Fixture.bottle(120, at: Fixture.date(daysAgo: 0, hour: 7)),
            Fixture.bottle(90, at: Fixture.date(daysAgo: 0, hour: 11)),
            Fixture.breastFeed(minutes: 15, endingAt: Fixture.date(daysAgo: 0, hour: 9)),
            Fixture.bottle(200, at: Fixture.date(daysAgo: 1, hour: 20)),
        ])

        #expect(summary.eventCount == 3)
        #expect(summary.bottleFeedCount == 2)
        #expect(summary.bottleTotalMilliliters == 210)
        #expect(summary.breastFeedCount == 1)
        #expect(summary.breastFeedTotalMinutes == 15)
    }

    @Test
    func ignoresDeletedEventsAndOtherCategories() throws {
        let summary = try summarize(.feeds, .today, events: [
            Fixture.bottle(120, at: Fixture.date(daysAgo: 0, hour: 7), isDeleted: true),
            Fixture.nappy(.wee, at: Fixture.date(daysAgo: 0, hour: 8)),
        ])

        #expect(summary.eventCount == 0)
        #expect(summary.bottleTotalMilliliters == 0)
    }

    @Test
    func sleepCountsOnlyCompletedSleepsAndTracksLongest() throws {
        let summary = try summarize(.sleep, .today, events: [
            Fixture.sleep(from: Fixture.date(daysAgo: 0, hour: 9), minutes: 45),
            Fixture.sleep(from: Fixture.date(daysAgo: 0, hour: 12), minutes: 90),
            Fixture.sleep(from: Fixture.date(daysAgo: 0, hour: 13, minute: 50), minutes: nil),
        ])

        #expect(summary.completedSleepCount == 2)
        #expect(summary.totalSleepMinutes == 135)
        #expect(summary.longestSleepMinutes == 90)
    }

    @Test
    func groupsNappiesByType() throws {
        let summary = try summarize(.nappies, .yesterday, events: [
            Fixture.nappy(.wee, at: Fixture.date(daysAgo: 1, hour: 6)),
            Fixture.nappy(.wee, at: Fixture.date(daysAgo: 1, hour: 10)),
            Fixture.nappy(.poo, at: Fixture.date(daysAgo: 1, hour: 12)),
        ])

        #expect(summary.nappyCountsByType[.wee] == 2)
        #expect(summary.nappyCountsByType[.poo] == 1)
        #expect(summary.nappyCountsByType[.dry] == nil)
    }

    @Test
    func countsFoodNamesAndAveragesPerDay() throws {
        let summary = try summarize(.food, .last7Days, events: [
            Fixture.food("Banana", at: Fixture.date(daysAgo: 0, hour: 12)),
            Fixture.food("Banana", at: Fixture.date(daysAgo: 3, hour: 12)),
            Fixture.food("Porridge", at: Fixture.date(daysAgo: 6, hour: 8)),
            Fixture.food("Carrot", at: Fixture.date(daysAgo: 7, hour: 8)),
        ])

        #expect(summary.itemCountsByName == ["Banana": 2, "Porridge": 1])
        #expect(summary.averageEventsPerDay == 3.0 / 7.0)
    }

    @Test
    func eventAtPeriodBoundaryBelongsToLaterPeriod() throws {
        let events = [try Fixture.bottle(100, at: Fixture.date(daysAgo: 6, hour: 0))]

        #expect(try summarize(.feeds, .last7Days, events: events).eventCount == 1)
        #expect(try summarize(.feeds, .previous7Days, events: events).eventCount == 0)
    }

    private func summarize(
        _ category: EventSummaryCategory,
        _ period: RelativePeriod,
        events: [BabyEvent]
    ) throws -> EventRangeSummary {
        try SummarizeEventsInRangeUseCase(
            eventRepository: AssistantStubEventRepository(events: events),
            calendar: Fixture.calendar
        ).execute(.init(childID: Fixture.childID, category: category, period: period, now: Fixture.now))
    }
}
