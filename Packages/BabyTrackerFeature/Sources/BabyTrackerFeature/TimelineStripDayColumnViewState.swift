import BabyTrackerDomain
import Foundation

public struct TimelineStripDayColumnViewState: Equatable, Identifiable, Sendable {
    public let date: Date
    public let shortWeekdayTitle: String
    public let dayNumberTitle: String
    public let isToday: Bool
    public let slots: [BabyEventKind?]

    public var id: Date {
        date
    }

    public init(
        date: Date,
        shortWeekdayTitle: String,
        dayNumberTitle: String,
        isToday: Bool,
        slots: [BabyEventKind?]
    ) {
        self.date = date
        self.shortWeekdayTitle = shortWeekdayTitle
        self.dayNumberTitle = dayNumberTitle
        self.isToday = isToday
        self.slots = slots
    }
}
