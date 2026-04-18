import Foundation

public struct PendingDriftNotification: Identifiable, Sendable {
    public enum Kind: Sendable {
        case sleep
        case inactivity
    }

    public let id: String
    public let kind: Kind
    public let childID: UUID
    public let childName: String
    public let fireDate: Date

    public init(id: String, kind: Kind, childID: UUID, childName: String, fireDate: Date) {
        self.id = id
        self.kind = kind
        self.childID = childID
        self.childName = childName
        self.fireDate = fireDate
    }
}
