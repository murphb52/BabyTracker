@testable import BabyTrackerAssistant
import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct AssistantToolTextTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private var now: Date {
        calendar.date(from: DateComponents(year: 2024, month: 6, day: 15, hour: 14))!
    }

    @Test
    func lastEventIncludesDetailTimeAndElapsed() throws {
        let fedAt = now.addingTimeInterval(-90 * 60)
        let feed = BabyEvent.bottleFeed(try BottleFeedEvent(
            metadata: EventMetadata(childID: UUID(), occurredAt: fedAt, createdBy: UUID()),
            amountMilliliters: 120,
            milkType: .formula
        ))

        let text = AssistantToolText.lastEvent(feed, category: .feeds, now: now, calendar: calendar)

        #expect(text == "Bottle feed: 120 ml of formula. Logged at 12:30 on Saturday 15 June, which was 1 hour 30 minutes ago.")
    }

    @Test
    func lastEventDescribesSleepInProgress() throws {
        let startedAt = now.addingTimeInterval(-45 * 60)
        let sleep = BabyEvent.sleep(try SleepEvent(
            metadata: EventMetadata(childID: UUID(), occurredAt: startedAt, createdBy: UUID()),
            startedAt: startedAt
        ))

        let text = AssistantToolText.lastEvent(sleep, category: .sleep, now: now, calendar: calendar)

        #expect(text.hasPrefix("Sleep in progress"))
        #expect(text.contains("45 minutes"))
    }

    @Test
    func lastEventSaysNothingLogged() {
        let text = AssistantToolText.lastEvent(nil, category: .bath, now: now, calendar: calendar)
        #expect(text == "No baths have been logged yet.")
    }

    @Test
    func emptySummarySaysNothingLogged() {
        let summary = EventRangeSummary(category: .nappies, period: .yesterday, eventCount: 0)
        #expect(AssistantToolText.summary(summary) == "No nappy changes were logged yesterday.")
    }

    @Test
    func nappySummaryUsesCaregiverWording() {
        let summary = EventRangeSummary(
            category: .nappies,
            period: .yesterday,
            eventCount: 3,
            nappyCountsByType: [.wee: 2, .poo: 1]
        )

        let text = AssistantToolText.summary(summary)

        #expect(text.contains("Nappy changes yesterday: 3 in total"))
        #expect(text.contains("Wet: 2, dirty: 1, wet and dirty: 0, dry: 0."))
        #expect(!text.contains("incomplete"))
    }

    @Test
    func summaryIncludingTodayIsMarkedIncomplete() {
        let summary = EventRangeSummary(category: .bath, period: .today, eventCount: 1)
        #expect(AssistantToolText.summary(summary).contains("still incomplete"))
    }

    @Test
    func sleepComparisonReportsChangeInDailySleep() {
        let current = EventRangeSummary(category: .sleep, period: .last7Days, eventCount: 14, completedSleepCount: 14, totalSleepMinutes: 7 * 600)
        let earlier = EventRangeSummary(category: .sleep, period: .previous7Days, eventCount: 7, completedSleepCount: 7, totalSleepMinutes: 7 * 540)

        let text = AssistantToolText.comparison(current: current, earlier: earlier)

        #expect(text.contains("Change in daily average count: +1.0 per day."))
        #expect(text.contains("Daily sleep changed by 1 hour more per day."))
    }

    @Test
    func patternListsBusiestHours() {
        var counts = Array(repeating: 0, count: 24)
        counts[13] = 4
        counts[9] = 2
        let pattern = DailyPattern(category: .sleep, period: .last7Days, countsByHour: counts)

        let text = AssistantToolText.pattern(pattern)

        #expect(text.contains("6 sleeps were logged"))
        #expect(text.contains("1pm and 2pm (4 times), 9am and 10am (2 times)"))
    }

    @Test
    func hourRangeWrapsAtMidnight() {
        #expect(AssistantToolText.hourRangeLabel(23) == "11pm and 12am")
        #expect(AssistantToolText.hourRangeLabel(0) == "12am and 1am")
    }
}
