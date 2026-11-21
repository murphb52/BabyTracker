import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct FindDailyPatternUseCaseTests {
    private typealias Fixture = AssistantQueryFixtures

    @Test
    func countsSleepByStartHour() throws {
        let pattern = try findPattern(.sleep, .last7Days, events: [
            Fixture.sleep(from: Fixture.date(daysAgo: 1, hour: 13, minute: 10), minutes: 60),
            Fixture.sleep(from: Fixture.date(daysAgo: 2, hour: 13, minute: 40), minutes: 50),
            Fixture.sleep(from: Fixture.date(daysAgo: 3, hour: 9), minutes: 30),
        ])

        #expect(pattern.countsByHour[13] == 2)
        #expect(pattern.countsByHour[9] == 1)
        #expect(pattern.eventCount == 3)
        #expect(pattern.busiestHours(limit: 2) == [13, 9])
    }

    @Test
    func excludesEventsOutsidePeriod() throws {
        let pattern = try findPattern(.feeds, .today, events: [
            Fixture.bottle(100, at: Fixture.date(daysAgo: 1, hour: 7)),
        ])

        #expect(pattern.eventCount == 0)
        #expect(pattern.busiestHours(limit: 3).isEmpty)
    }

    private func findPattern(
        _ category: EventSummaryCategory,
        _ period: RelativePeriod,
        events: [BabyEvent]
    ) throws -> DailyPattern {
        try FindDailyPatternUseCase(
            eventRepository: AssistantStubEventRepository(events: events),
            calendar: Fixture.calendar
        ).execute(.init(childID: Fixture.childID, category: category, period: period, now: Fixture.now))
    }
}
