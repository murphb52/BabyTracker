import BabyTrackerDomain
import Foundation

public struct HomeTimelineEventViewState: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let kind: BabyEventKind
    public let title: String
    public let detailText: String
    public let timeText: String
    public let isOngoing: Bool

    public init(
        id: UUID,
        kind: BabyEventKind,
        title: String,
        detailText: String,
        timeText: String,
        isOngoing: Bool
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detailText = detailText
        self.timeText = timeText
        self.isOngoing = isOngoing
    }
}
