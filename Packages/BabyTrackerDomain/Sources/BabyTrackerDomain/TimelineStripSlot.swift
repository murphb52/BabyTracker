import Foundation

public struct TimelineStripSlot: Equatable, Sendable {
    public let kind: BabyEventKind?

    public init(kind: BabyEventKind?) {
        self.kind = kind
    }
}
