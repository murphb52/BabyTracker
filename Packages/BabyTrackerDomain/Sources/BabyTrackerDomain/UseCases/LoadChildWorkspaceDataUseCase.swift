import Foundation

/// Loads all data required to display a child's workspace: the full event
/// timeline, the active sleep session, the child's memberships, the user
/// identities behind those memberships, and the local user's resolved
/// membership. Throws if the local user no longer has an active membership
/// for the child (e.g. the sync hasn't arrived yet after being removed).
@MainActor
public struct LoadChildWorkspaceDataUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let localUserID: UUID

        public init(childID: UUID, localUserID: UUID) {
            self.childID = childID
            self.localUserID = localUserID
        }
    }

    public struct Output {
        public let events: [BabyEvent]
        public let activeSleep: SleepEvent?
        public let memberships: [Membership]
        public let membershipUsers: [UserIdentity]
        public let currentMembership: Membership
    }

    private let eventRepository: any EventRepository
    private let membershipRepository: any MembershipRepository
    private let userIdentityRepository: any UserIdentityRepository

    public init(
        eventRepository: any EventRepository,
        membershipRepository: any MembershipRepository,
        userIdentityRepository: any UserIdentityRepository
    ) {
        self.eventRepository = eventRepository
        self.membershipRepository = membershipRepository
        self.userIdentityRepository = userIdentityRepository
    }

    public func execute(_ input: Input) throws -> Output {
        let events = try eventRepository.loadTimeline(for: input.childID, includingDeleted: false)
        let activeSleep = try eventRepository.loadActiveSleepEvent(for: input.childID)
        let memberships = try membershipRepository.loadMemberships(for: input.childID)
        let membershipUsers = try userIdentityRepository.loadUsers(for: memberships.map(\.userID))

        guard let currentMembership = memberships.first(where: {
            $0.userID == input.localUserID && $0.status == .active
        }) else {
            throw ChildProfileValidationError.invalidMembershipTransition(from: .removed, to: .active)
        }

        return Output(
            events: events,
            activeSleep: activeSleep,
            memberships: memberships,
            membershipUsers: membershipUsers,
            currentMembership: currentMembership
        )
    }
}
