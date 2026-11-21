import Foundation

/// A period described relative to "now", so the language model never has to
/// work out calendar dates itself.
///
/// Every period resolves to whole calendar days as a half-open interval
/// (`start <= date < end`). Periods that include today run to the end of
/// today so nothing logged today is cut off.
public enum RelativePeriod: String, CaseIterable, Equatable, Sendable {
    case today
    case yesterday
    case last7Days
    case previous7Days
    case last30Days
    case previous30Days

    public var dayCount: Int {
        switch self {
        case .today, .yesterday: 1
        case .last7Days, .previous7Days: 7
        case .last30Days, .previous30Days: 30
        }
    }

    public var displayName: String {
        switch self {
        case .today: "today"
        case .yesterday: "yesterday"
        case .last7Days: "the last 7 days"
        case .previous7Days: "the 7 days before that"
        case .last30Days: "the last 30 days"
        case .previous30Days: "the 30 days before that"
        }
    }

    public func interval(now: Date, calendar: Calendar) -> DateInterval {
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = day(offset: 1, from: startOfToday, calendar: calendar)

        switch self {
        case .today:
            return DateInterval(start: startOfToday, end: startOfTomorrow)
        case .yesterday:
            return DateInterval(start: day(offset: -1, from: startOfToday, calendar: calendar), end: startOfToday)
        case .last7Days, .last30Days:
            let start = day(offset: -(dayCount - 1), from: startOfToday, calendar: calendar)
            return DateInterval(start: start, end: startOfTomorrow)
        case .previous7Days, .previous30Days:
            let end = day(offset: -(dayCount - 1), from: startOfToday, calendar: calendar)
            let start = day(offset: -dayCount, from: end, calendar: calendar)
            return DateInterval(start: start, end: end)
        }
    }

    private func day(offset: Int, from date: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: offset, to: date) ?? date
    }
}

extension DateInterval {
    /// Half-open containment used by the assistant queries, so adjacent
    /// periods never count the same event twice.
    func containsHalfOpen(_ date: Date) -> Bool {
        date >= start && date < end
    }
}
