import BabyTrackerDomain
import Foundation

/// Provides static demo data for the interactive onboarding feature showcase pages.
/// All data is fabricated and never persisted.
@MainActor
enum OnboardingDemoDataFactory {

    static var summaryViewModel: SummaryViewModel {
        SummaryScreenPreviewFactory.summaryViewModel
    }

    /// Seven days of plausible timeline strip columns centred on today,
    /// suitable for the `TimelineWeekView` demo embed.
    static var timelineStripColumns: [TimelineStripDayColumnViewState] {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        return (-6...0).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            formatter.dateFormat = "EEE"
            let weekday = formatter.string(from: date)
            formatter.dateFormat = "d"
            let dayNumber = formatter.string(from: date)

            return TimelineStripDayColumnViewState(
                date: date,
                shortWeekdayTitle: weekday,
                dayNumberTitle: dayNumber,
                isToday: dayOffset == 0,
                slots: slots(forDayOffset: dayOffset)
            )
        }
    }

    // MARK: - Private

    private static func slots(forDayOffset offset: Int) -> [BabyEventKind?] {
        // 24 slots, one per hour (index 0 = midnight)
        var result: [BabyEventKind?] = Array(repeating: nil, count: 24)

        // Night sleep: midnight through early morning
        for hour in 0...4 { result[hour] = .sleep }

        // Morning routine varies slightly by day
        let feedHour = (offset % 2 == 0) ? 6 : 7
        result[feedHour] = .breastFeed
        result[feedHour + 1] = .nappy

        // Mid-morning nap
        result[9] = .sleep
        result[10] = .sleep

        // Midday feed
        result[11] = .bottleFeed
        result[12] = .nappy

        // Afternoon nap — slightly staggered to look natural
        let napHour = 13 + abs(offset % 2)
        result[napHour] = .sleep
        result[napHour + 1] = .sleep

        // Afternoon feed
        result[15] = .bottleFeed

        // Evening routine
        result[17] = .nappy
        result[18] = .breastFeed

        // Bedtime
        result[19] = .sleep
        result[20] = .sleep

        // Late night feed — only on some days to vary the pattern
        if offset % 3 == 0 {
            result[23] = .bottleFeed
        }

        return result
    }
}
