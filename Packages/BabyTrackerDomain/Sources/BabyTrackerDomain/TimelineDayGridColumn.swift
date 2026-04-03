import Foundation

public struct TimelineDayGridColumn: Equatable, Sendable {
    public let kind: TimelineDayGridColumnKind
    public let placements: [TimelineDayGridPlacement]

    public init(
        kind: TimelineDayGridColumnKind,
        placements: [TimelineDayGridPlacement]
    ) {
        self.kind = kind
        self.placements = placements
    }
}
