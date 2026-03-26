import Foundation

public struct TimelineStripDayColumn: Equatable, Sendable {
    public let date: Date
    public let slots: [TimelineStripSlot]

    public init(
        date: Date,
        slots: [TimelineStripSlot]
    ) {
        self.date = date
        self.slots = slots
    }
}
