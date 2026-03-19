import BabyTrackerDomain
import Foundation

public struct CaregiverMembershipViewState: Equatable, Identifiable, Sendable {
    public let user: UserIdentity
    public let membership: Membership

    public var id: UUID {
        membership.id
    }

    public var displayName: String {
        user.displayName
    }

    public var statusLabel: String {
        switch membership.status {
        case .active:
            membership.role == .owner ? "Owner" : "Active caregiver"
        case .invited:
            "Invited"
        case .removed:
            "Removed"
        }
    }

    public var secondaryLabel: String {
        if membership.role == .owner {
            "Created \(membership.invitedAt.formatted(date: .abbreviated, time: .omitted))"
        } else if let acceptedAt = membership.acceptedAt {
            "Accepted \(acceptedAt.formatted(date: .abbreviated, time: .omitted))"
        } else {
            "Invited \(membership.invitedAt.formatted(date: .abbreviated, time: .omitted))"
        }
    }

    public init(user: UserIdentity, membership: Membership) {
        self.user = user
        self.membership = membership
    }
}
