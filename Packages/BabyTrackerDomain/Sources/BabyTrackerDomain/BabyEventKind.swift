import Foundation

public enum BabyEventKind: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case bath
    case breastFeed
    case bottleFeed
    case food
    case sleep
    case nappy
    case medication
}
