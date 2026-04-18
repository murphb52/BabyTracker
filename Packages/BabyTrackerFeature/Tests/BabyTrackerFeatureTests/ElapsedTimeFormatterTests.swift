@testable import BabyTrackerFeature
import Foundation
import Testing

struct ElapsedTimeFormatterTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private var locale: Locale { Locale(identifier: "en_US_POSIX") }

    private var referenceDate: Date {
        calendar.date(from: DateComponents(year: 2026, month: 4, day: 18, hour: 12, minute: 0))!
    }

    @Test func justNow_whenUnderOneMinute() {
        let date = referenceDate.addingTimeInterval(-30)
        #expect(
            ElapsedTimeFormatter.string(
                from: date,
                relativeTo: referenceDate,
                calendar: calendar,
                locale: locale
            ) == "Just now"
        )
    }

    @Test func justNow_whenExactlyNow() {
        #expect(
            ElapsedTimeFormatter.string(
                from: referenceDate,
                relativeTo: referenceDate,
                calendar: calendar,
                locale: locale
            ) == "Just now"
        )
    }

    @Test func minutesOnly_whenUnderOneHour() {
        let date = referenceDate.addingTimeInterval(-45 * 60)
        #expect(
            ElapsedTimeFormatter.string(
                from: date,
                relativeTo: referenceDate,
                calendar: calendar,
                locale: locale
            ) == "45m"
        )
    }

    @Test func singularMinute() {
        let date = referenceDate.addingTimeInterval(-60)
        #expect(
            ElapsedTimeFormatter.string(
                from: date,
                relativeTo: referenceDate,
                calendar: calendar,
                locale: locale
            ) == "1m"
        )
    }

    @Test func hoursAndMinutes() {
        let date = referenceDate.addingTimeInterval(-(90 * 60))
        #expect(
            ElapsedTimeFormatter.string(
                from: date,
                relativeTo: referenceDate,
                calendar: calendar,
                locale: locale
            ) == "1h 30m"
        )
    }

    @Test func hoursOnly_whenExactHours() {
        let date = referenceDate.addingTimeInterval(-(2 * 60 * 60))
        #expect(
            ElapsedTimeFormatter.string(
                from: date,
                relativeTo: referenceDate,
                calendar: calendar,
                locale: locale
            ) == "2h"
        )
    }

    @Test func singularHour_withMinutes() {
        let date = referenceDate.addingTimeInterval(-(61 * 60))
        #expect(
            ElapsedTimeFormatter.string(
                from: date,
                relativeTo: referenceDate,
                calendar: calendar,
                locale: locale
            ) == "1h 1m"
        )
    }

    @Test func yesterdayUsesYesterdayAtFormat() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 4, day: 17, hour: 8, minute: 42))!
        #expect(
            ElapsedTimeFormatter.string(
                from: date,
                relativeTo: referenceDate,
                calendar: calendar,
                locale: locale
            ) == "Yesterday at 8:42 AM"
        )
    }

    @Test func olderThanYesterdayWithinWeekUsesWeekdayAndTime() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 4, day: 15, hour: 21, minute: 15))!
        #expect(
            ElapsedTimeFormatter.string(
                from: date,
                relativeTo: referenceDate,
                calendar: calendar,
                locale: locale
            ) == "Wed 9:15 PM"
        )
    }

    @Test func olderThanWeekUsesMonthDayAndTime() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 4, day: 8, hour: 6, minute: 5))!
        #expect(
            ElapsedTimeFormatter.string(
                from: date,
                relativeTo: referenceDate,
                calendar: calendar,
                locale: locale
            ) == "Apr 8 6:05 AM"
        )
    }
}
