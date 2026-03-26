import Foundation

public struct TimelineStripDataset: Equatable, Sendable {
    public let columns: [TimelineStripDayColumn]
    public let todayIndex: Int

    public init(
        columns: [TimelineStripDayColumn],
        todayIndex: Int
    ) {
        self.columns = columns
        self.todayIndex = todayIndex
    }
}
