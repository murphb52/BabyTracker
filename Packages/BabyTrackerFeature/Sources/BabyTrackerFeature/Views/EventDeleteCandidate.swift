import BabyTrackerDomain
import Foundation

public struct EventDeleteCandidate: Identifiable {
    public let id: UUID
    public let kind: BabyEventKind
    public let title: String
    public let timestampText: String

    public init(event: EventCardViewState) {
        id = event.id
        kind = event.kind
        title = event.title
        timestampText = event.timestampText
    }

    public init(event: TimelineDayGridItemViewState) {
        id = event.primaryEventID ?? UUID()
        kind = event.eventKind
        title = event.title
        timestampText = event.timeText
    }

    public var dialogTitle: String {
        switch kind {
        case .breastFeed, .bottleFeed:
            return "Delete Feed?"
        case .sleep:
            return "Delete Sleep?"
        case .nappy:
            return "Delete Nappy?"
        }
    }

    public var confirmButtonTitle: String {
        switch kind {
        case .breastFeed, .bottleFeed:
            return "Delete Feed"
        case .sleep:
            return "Delete Sleep"
        case .nappy:
            return "Delete Nappy"
        }
    }
}
