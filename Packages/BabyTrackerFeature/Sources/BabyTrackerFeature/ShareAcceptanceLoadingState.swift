import Foundation

public struct ShareAcceptanceLoadingState: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        case syncing
        case readyToContinue
    }

    public let childName: String
    public let phase: Phase

    public init(childName: String, phase: Phase) {
        self.childName = childName
        self.phase = phase
    }

    public static let acceptingSharedChild = ShareAcceptanceLoadingState(
        childName: "your child profile",
        phase: .syncing
    )
}
