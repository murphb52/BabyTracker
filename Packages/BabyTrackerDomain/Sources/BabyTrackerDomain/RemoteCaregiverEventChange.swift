import Foundation

public struct RemoteCaregiverEventChange: Equatable, Sendable {
    public let actorDisplayName: String
    public let event: BabyEvent
    public let isDeleted: Bool

    public init(actorDisplayName: String, event: BabyEvent, isDeleted: Bool) {
        self.actorDisplayName = actorDisplayName
        self.event = event
        self.isDeleted = isDeleted
    }
}
