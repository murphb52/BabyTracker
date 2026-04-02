import Foundation

public struct TimelineDayPageState: Equatable, Identifiable, Sendable {
    public let date: Date
    public let dayTitle: String
    public let shortWeekdayTitle: String
    public let dayNumberTitle: String
    public let isToday: Bool
    public let blocks: [TimelineEventBlockViewState]
    public let emptyStateTitle: String
    public let emptyStateMessage: String

    public var id: Date {
        date
    }

    public init(
        date: Date,
        dayTitle: String,
        shortWeekdayTitle: String,
        dayNumberTitle: String,
        isToday: Bool,
        blocks: [TimelineEventBlockViewState],
        emptyStateTitle: String,
        emptyStateMessage: String
    ) {
        self.date = date
        self.dayTitle = dayTitle
        self.shortWeekdayTitle = shortWeekdayTitle
        self.dayNumberTitle = dayNumberTitle
        self.isToday = isToday
        self.blocks = blocks
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateMessage = emptyStateMessage
    }
}
