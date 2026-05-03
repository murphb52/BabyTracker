import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

struct TrendsSummaryCalculatorTests {
    @Test
    func bathTrendCountsAreGroupedPerDayAndAverageOverNonZeroDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 12)))
        let todayBath = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 9)))
        let yesterdayBathOne = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 25, hour: 8)))
        let yesterdayBathTwo = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 25, hour: 18)))

        let events: [BabyEvent] = [
            .bath(BathEvent(
                metadata: EventMetadata(childID: childID, occurredAt: todayBath, createdAt: todayBath, createdBy: userID),
                usedShampoo: true,
                usedSoap: false
            )),
            .bath(BathEvent(
                metadata: EventMetadata(childID: childID, occurredAt: yesterdayBathOne, createdAt: yesterdayBathOne, createdBy: userID),
                usedShampoo: false,
                usedSoap: true
            )),
            .bath(BathEvent(
                metadata: EventMetadata(childID: childID, occurredAt: yesterdayBathTwo, createdAt: yesterdayBathTwo, createdBy: userID),
                usedShampoo: true,
                usedSoap: true
            )),
        ]

        let data = TrendsSummaryCalculator.makeData(
            from: events,
            range: .sevenDays,
            now: now,
            calendar: calendar
        )

        #expect(data.dailyBath.first(where: { calendar.isDate($0.date, inSameDayAs: yesterdayBathOne) })?.count == 2)
        #expect(data.dailyBath.first(where: { calendar.isDate($0.date, inSameDayAs: todayBath) })?.count == 1)
        #expect(data.avgDailyBaths == 2)
    }
}
