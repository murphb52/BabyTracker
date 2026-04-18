import Foundation

enum ElapsedTimeFormatter {
    static func string(
        from date: Date,
        relativeTo referenceDate: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let interval = referenceDate.timeIntervalSince(date)
        guard interval >= 60 else { return "Just now" }

        let totalMinutes = Int(interval / 60)
        if totalMinutes >= 24 * 60 {
            return olderThanDayString(
                from: date,
                relativeTo: referenceDate,
                calendar: calendar,
                locale: locale
            )
        }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return "\(totalMinutes)m"
        } else if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }

    private static func olderThanDayString(
        from date: Date,
        relativeTo referenceDate: Date,
        calendar: Calendar,
        locale: Locale
    ) -> String {
        if calendar.isDateInYesterday(date) || isYesterday(date, relativeTo: referenceDate, calendar: calendar) {
            return "Yesterday at \(timeText(for: date, calendar: calendar, locale: locale))"
        }

        if let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: referenceDate)),
           date >= sevenDaysAgo {
            return "\(weekdayText(for: date, locale: locale)) \(timeText(for: date, calendar: calendar, locale: locale))"
        }

        return "\(dateText(for: date, calendar: calendar, locale: locale)) \(timeText(for: date, calendar: calendar, locale: locale))"
    }

    private static func isYesterday(_ date: Date, relativeTo referenceDate: Date, calendar: Calendar) -> Bool {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate) else {
            return false
        }

        return calendar.isDate(date, inSameDayAs: yesterday)
    }

    private static func timeText(for date: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("jm")
        return formatter.string(from: date)
    }

    private static func weekdayText(for date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date)
    }

    private static func dateText(for date: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter.string(from: date)
    }
}
