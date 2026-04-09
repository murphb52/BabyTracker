import BabyTrackerDomain
import Foundation

public enum TodaySummaryCalculator {
    public static func makeData(
        from allEvents: [BabyEvent],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        summaryBuilder: any TodaySummaryBuilding = BuildTodaySummaryUseCase()
    ) -> TodaySummaryData {
        let summary = summaryBuilder.execute(events: allEvents, now: now, calendar: calendar)
        return TodaySummaryData(summary: summary)
    }
}
