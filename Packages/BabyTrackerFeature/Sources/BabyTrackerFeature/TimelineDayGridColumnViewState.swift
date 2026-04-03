import BabyTrackerDomain
import Foundation

public struct TimelineDayGridColumnViewState: Equatable, Sendable {
    public let kind: TimelineDayGridColumnKind
    public let title: String
    public let items: [TimelineDayGridItemViewState]

    public init(
        kind: TimelineDayGridColumnKind,
        title: String,
        items: [TimelineDayGridItemViewState]
    ) {
        self.kind = kind
        self.title = title
        self.items = items
    }
}
