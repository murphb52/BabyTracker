import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct RelativePeriodTests {
    private let calendar = AssistantQueryFixtures.calendar
    private let now = AssistantQueryFixtures.now

    @Test
    func todayRunsFromMidnightToMidnight() {
        let interval = RelativePeriod.today.interval(now: now, calendar: calendar)
        #expect(interval.start == AssistantQueryFixtures.date(daysAgo: 0, hour: 0))
        #expect(interval.end == AssistantQueryFixtures.date(daysAgo: -1, hour: 0))
    }

    @Test
    func last7DaysIncludesTodayAndSixPreviousDays() {
        let interval = RelativePeriod.last7Days.interval(now: now, calendar: calendar)
        #expect(interval.start == AssistantQueryFixtures.date(daysAgo: 6, hour: 0))
        #expect(interval.end == AssistantQueryFixtures.date(daysAgo: -1, hour: 0))
    }

    @Test
    func previous7DaysEndsWhereLast7DaysStarts() {
        let last = RelativePeriod.last7Days.interval(now: now, calendar: calendar)
        let previous = RelativePeriod.previous7Days.interval(now: now, calendar: calendar)
        #expect(previous.end == last.start)
        #expect(previous.start == AssistantQueryFixtures.date(daysAgo: 13, hour: 0))
    }

    @Test
    func yesterdayEndsAtStartOfToday() {
        let interval = RelativePeriod.yesterday.interval(now: now, calendar: calendar)
        #expect(interval.start == AssistantQueryFixtures.date(daysAgo: 1, hour: 0))
        #expect(interval.end == AssistantQueryFixtures.date(daysAgo: 0, hour: 0))
    }
}
