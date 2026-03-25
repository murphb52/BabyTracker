import Foundation

@MainActor
public struct DeleteEventUseCase: UseCase {
    public struct Input {
        public let eventID: UUID
        public let localUserID: UUID
        public let membership: Membership

        public init(eventID: UUID, localUserID: UUID, membership: Membership) {
            self.eventID = eventID
            self.localUserID = localUserID
            self.membership = membership
        }
    }

    private let eventRepository: any EventRepository

    public init(eventRepository: any EventRepository) {
        self.eventRepository = eventRepository
    }

    /// Returns the event snapshot before deletion, for use in undo state.
    /// Returns nil if the event does not exist.
    public func execute(_ input: Input) throws -> BabyEvent? {
        guard ChildAccessPolicy.canPerform(.deleteEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        guard let event = try eventRepository.loadEvent(id: input.eventID) else {
            return nil
        }

        try eventRepository.softDeleteEvent(
            id: input.eventID,
            deletedAt: .now,
            deletedBy: input.localUserID
        )
        return event
    }
}
