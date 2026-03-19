import Foundation

public enum SyncRecordType: String, Equatable, Sendable {
    case child
    case user
    case membership
    case breastFeedEvent
    case bottleFeedEvent
    case sleepEvent
    case nappyEvent
}
