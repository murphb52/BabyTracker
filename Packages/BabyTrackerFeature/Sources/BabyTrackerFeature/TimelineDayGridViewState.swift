import Foundation

public struct TimelineDayGridViewState: Equatable, Sendable {
    public let slotMinutes: Int
    public let columns: [TimelineDayGridColumnViewState]

    public init(
        slotMinutes: Int,
        columns: [TimelineDayGridColumnViewState]
    ) {
        self.slotMinutes = slotMinutes
        self.columns = columns
    }
}
