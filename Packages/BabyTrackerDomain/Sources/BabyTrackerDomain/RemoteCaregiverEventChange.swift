import Foundation

public struct RemoteCaregiverEventChange: Equatable, Sendable {
    public let actorDisplayName: String
    public let event: BabyEvent

    public init(actorDisplayName: String, event: BabyEvent) {
        self.actorDisplayName = actorDisplayName
        self.event = event
    }
}
