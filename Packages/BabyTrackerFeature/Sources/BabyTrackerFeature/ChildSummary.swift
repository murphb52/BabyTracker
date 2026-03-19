import BabyTrackerDomain
import Foundation

public struct ChildSummary: Equatable, Identifiable, Sendable {
    public let child: Child
    public let membership: Membership

    public var id: UUID {
        child.id
    }

    public init(child: Child, membership: Membership) {
        self.child = child
        self.membership = membership
    }
}
