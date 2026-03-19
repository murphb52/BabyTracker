import Foundation

public enum BabyEventKind: String, Codable, Equatable, Hashable, Sendable {
    case breastFeed
    case bottleFeed
    case sleep
    case nappy
}
