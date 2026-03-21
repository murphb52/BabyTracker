import BabyTrackerDomain
import BabyTrackerFeature
import Foundation

struct EventDeleteCandidate: Identifiable {
    let id: UUID
    let kind: BabyEventKind
    let title: String
    let timestampText: String

    init(event: EventCardViewState) {
        id = event.id
        kind = event.kind
        title = event.title
        timestampText = event.timestampText
    }

    init(event: TimelineEventBlockViewState) {
        id = event.id
        kind = event.kind
        title = event.title
        timestampText = event.timeText
    }

    var dialogTitle: String {
        switch kind {
        case .breastFeed, .bottleFeed:
            return "Delete Feed?"
        case .sleep:
            return "Delete Sleep?"
        case .nappy:
            return "Delete Nappy?"
        }
    }

    var confirmButtonTitle: String {
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
