import Foundation

/// The groups of events the assistant can ask about. Feeds combine breast
/// and bottle feeds because caregivers usually ask about "feeds" as a whole.
public enum EventSummaryCategory: String, CaseIterable, Equatable, Sendable {
    case feeds
    case sleep
    case nappies
    case food
    case medication
    case bath

    public var eventKinds: Set<BabyEventKind> {
        switch self {
        case .feeds: [.breastFeed, .bottleFeed]
        case .sleep: [.sleep]
        case .nappies: [.nappy]
        case .food: [.food]
        case .medication: [.medication]
        case .bath: [.bath]
        }
    }

    public func includes(_ event: BabyEvent) -> Bool {
        eventKinds.contains(event.kind)
    }
}
