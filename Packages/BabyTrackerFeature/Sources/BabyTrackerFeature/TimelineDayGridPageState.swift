import Foundation

public struct TimelineDayGridPageState: Equatable, Identifiable, Sendable {
    public let date: Date
    public let dayTitle: String
    public let shortWeekdayTitle: String
    public let isToday: Bool
    public let grid: TimelineDayGridViewState?
    public let emptyStateTitle: String
    public let emptyStateMessage: String

    public var id: Date {
        date
    }

    public init(
        date: Date,
        dayTitle: String,
        shortWeekdayTitle: String,
        isToday: Bool,
        grid: TimelineDayGridViewState?,
        emptyStateTitle: String,
        emptyStateMessage: String
    ) {
        self.date = date
        self.dayTitle = dayTitle
        self.shortWeekdayTitle = shortWeekdayTitle
        self.isToday = isToday
        self.grid = grid
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateMessage = emptyStateMessage
    }
}
