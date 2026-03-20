import BabyTrackerDomain
import Foundation

public struct TimelineEventRowViewState: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let kind: BabyEventKind
    public let title: String
    public let detailText: String
    public let timeText: String
    public let secondaryTimeText: String?
    public let overlapText: String?
    public let gapFromPreviousText: String?
    public let actionPayload: TimelineEventActionPayload

    public init(
        id: UUID,
        kind: BabyEventKind,
        title: String,
        detailText: String,
        timeText: String,
        secondaryTimeText: String?,
        overlapText: String?,
        gapFromPreviousText: String?,
        actionPayload: TimelineEventActionPayload
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detailText = detailText
        self.timeText = timeText
        self.secondaryTimeText = secondaryTimeText
        self.overlapText = overlapText
        self.gapFromPreviousText = gapFromPreviousText
        self.actionPayload = actionPayload
    }
}
