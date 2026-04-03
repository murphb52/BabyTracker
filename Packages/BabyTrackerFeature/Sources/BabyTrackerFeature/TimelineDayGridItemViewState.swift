import BabyTrackerDomain
import Foundation

public struct TimelineDayGridItemViewState: Equatable, Identifiable, Sendable {
    public let id: String
    public let columnKind: TimelineDayGridColumnKind
    public let startSlotIndex: Int
    public let endSlotIndex: Int
    public let eventIDs: [UUID]
    public let count: Int
    public let title: String
    public let detailText: String
    public let timeText: String
    public let actionPayloads: [EventActionPayload]
    public let groupedEntries: [EventCardViewState]

    public init(
        id: String,
        columnKind: TimelineDayGridColumnKind,
        startSlotIndex: Int,
        endSlotIndex: Int,
        eventIDs: [UUID],
        count: Int,
        title: String,
        detailText: String,
        timeText: String,
        actionPayloads: [EventActionPayload],
        groupedEntries: [EventCardViewState] = []
    ) {
        self.id = id
        self.columnKind = columnKind
        self.startSlotIndex = startSlotIndex
        self.endSlotIndex = endSlotIndex
        self.eventIDs = eventIDs
        self.count = count
        self.title = title
        self.detailText = detailText
        self.timeText = timeText
        self.actionPayloads = actionPayloads
        self.groupedEntries = groupedEntries
    }

    public var isGrouped: Bool {
        count > 1
    }

    public var isInteractive: Bool {
        count == 1 && actionPayloads.count == 1
    }

    public var opensGroupedSheet: Bool {
        isGrouped && !groupedEntries.isEmpty
    }

    public var primaryEventID: UUID? {
        eventIDs.first
    }

    public var primaryActionPayload: EventActionPayload? {
        actionPayloads.first
    }

    public var eventKind: BabyEventKind {
        switch columnKind {
        case .sleep:
            .sleep
        case .nappy:
            .nappy
        case .bottleFeed:
            .bottleFeed
        case .breastFeed:
            .breastFeed
        }
    }
}
