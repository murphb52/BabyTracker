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
}
