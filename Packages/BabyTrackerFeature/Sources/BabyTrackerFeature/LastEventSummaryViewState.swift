import BabyTrackerDomain
import Foundation

public struct LastEventSummaryViewState: Equatable, Sendable {
    public let kind: BabyEventKind
    public let title: String
    public let detailText: String?
    public let occurredAt: Date

    public init(
        kind: BabyEventKind,
        title: String,
        detailText: String?,
        occurredAt: Date
    ) {
        self.kind = kind
        self.title = title
        self.detailText = detailText
        self.occurredAt = occurredAt
    }
}
