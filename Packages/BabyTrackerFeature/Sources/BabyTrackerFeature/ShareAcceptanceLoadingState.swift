import Foundation

public struct ShareAcceptanceLoadingState: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        case syncing
        case completed
    }

    public let phase: Phase
    public let childName: String?

    public init(phase: Phase, childName: String?) {
        self.phase = phase
        self.childName = childName
    }

    public var title: String {
        switch phase {
        case .syncing:
            if let childName {
                return "You joined \(childName)'s profile"
            }
            return "Invitation accepted"
        case .completed:
            if let childName {
                return "\(childName) is ready"
            }
            return "Child profile is ready"
        }
    }

    public var message: String {
        switch phase {
        case .syncing:
            if let childName {
                return "You've accepted the invitation for \(childName). We're syncing data now — this can take a little while if there's a lot of history."
            }
            return "You've accepted the invitation. We're syncing data now — this can take a little while if there's a lot of history."
        case .completed:
            return "Sync is complete. Continue to open the child profile."
        }
    }

    public static func syncing(childName: String?) -> ShareAcceptanceLoadingState {
        ShareAcceptanceLoadingState(phase: .syncing, childName: childName)
    }

    public static func completed(childName: String?) -> ShareAcceptanceLoadingState {
        ShareAcceptanceLoadingState(phase: .completed, childName: childName)
    }
}
