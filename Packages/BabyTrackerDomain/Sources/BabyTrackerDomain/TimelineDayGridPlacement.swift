import Foundation

public struct TimelineDayGridPlacement: Equatable, Sendable {
    public let columnKind: TimelineDayGridColumnKind
    public let startSlotIndex: Int
    public let endSlotIndex: Int
    public let eventIDs: [UUID]

    public init(
        columnKind: TimelineDayGridColumnKind,
        startSlotIndex: Int,
        endSlotIndex: Int,
        eventIDs: [UUID]
    ) {
        self.columnKind = columnKind
        self.startSlotIndex = startSlotIndex
        self.endSlotIndex = endSlotIndex
        self.eventIDs = eventIDs
    }
}
