import Foundation

public enum BabyEventKind: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case breastFeed
    case bottleFeed
    case sleep
    case nappy
}
