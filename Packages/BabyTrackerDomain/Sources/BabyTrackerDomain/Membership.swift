import Foundation

public struct Membership: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let childID: UUID
    public let userID: UUID
    public var role: MembershipRole
    public var status: MembershipStatus
    public let invitedAt: Date
    public var acceptedAt: Date?

    public init(
        id: UUID = UUID(),
        childID: UUID,
        userID: UUID,
        role: MembershipRole,
        status: MembershipStatus,
        invitedAt: Date = Date(),
        acceptedAt: Date? = nil
    ) {
        self.id = id
        self.childID = childID
        self.userID = userID
        self.role = role
        self.status = status
        self.invitedAt = invitedAt
        self.acceptedAt = acceptedAt
    }

    public static func owner(
        id: UUID = UUID(),
        childID: UUID,
        userID: UUID,
        createdAt: Date = Date()
    ) -> Membership {
        Membership(
            id: id,
            childID: childID,
            userID: userID,
            role: .owner,
            status: .active,
            invitedAt: createdAt,
            acceptedAt: createdAt
        )
    }

    public static func invitedCaregiver(
        id: UUID = UUID(),
        childID: UUID,
        userID: UUID,
        invitedAt: Date = Date()
    ) -> Membership {
        Membership(
            id: id,
            childID: childID,
            userID: userID,
            role: .caregiver,
            status: .invited,
            invitedAt: invitedAt,
            acceptedAt: nil
        )
    }

    public func activated(at acceptedAt: Date = Date()) throws -> Membership {
        guard role == .caregiver else {
            throw ChildProfileValidationError.invalidMembershipTransition(
                from: status,
                to: .active
            )
        }

        guard status == .invited else {
            throw ChildProfileValidationError.invalidMembershipTransition(
                from: status,
                to: .active
            )
        }

        var updatedMembership = self
        updatedMembership.status = .active
        updatedMembership.acceptedAt = acceptedAt
        return updatedMembership
    }

    public func removed() throws -> Membership {
        switch status {
        case .invited, .active:
            var updatedMembership = self
            updatedMembership.status = .removed
            return updatedMembership
        case .removed:
            throw ChildProfileValidationError.invalidMembershipTransition(
                from: .removed,
                to: .removed
            )
        }
    }
}
