import BabyTrackerDomain
import Foundation

public struct TimelineEventBlockViewState: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let kind: BabyEventKind
    public let title: String
    public let detailText: String
    public let timeText: String
    public let startMinute: Int
    public let endMinute: Int
    public let laneIndex: Int
    public let laneCount: Int
    public let actionPayload: TimelineEventActionPayload

    public init(
        id: UUID,
        kind: BabyEventKind,
        title: String,
        detailText: String,
        timeText: String,
        startMinute: Int,
        endMinute: Int,
        laneIndex: Int,
        laneCount: Int,
        actionPayload: TimelineEventActionPayload
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detailText = detailText
        self.timeText = timeText
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.laneIndex = laneIndex
        self.laneCount = laneCount
        self.actionPayload = actionPayload
    }

    public func updatingLayout(
        laneIndex: Int,
        laneCount: Int
    ) -> TimelineEventBlockViewState {
        TimelineEventBlockViewState(
            id: id,
            kind: kind,
            title: title,
            detailText: detailText,
            timeText: timeText,
            startMinute: startMinute,
            endMinute: endMinute,
            laneIndex: laneIndex,
            laneCount: laneCount,
            actionPayload: actionPayload
        )
    }
}
