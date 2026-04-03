import Foundation

public struct TimelineDayGridDataset: Equatable, Sendable {
    public let day: Date
    public let slotMinutes: Int
    public let columns: [TimelineDayGridColumn]

    public init(
        day: Date,
        slotMinutes: Int,
        columns: [TimelineDayGridColumn]
    ) {
        self.day = day
        self.slotMinutes = slotMinutes
        self.columns = columns
    }
}
