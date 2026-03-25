import Foundation

@MainActor
public struct UpdateBreastFeedUseCase: UseCase {
    public struct Input {
        public let eventID: UUID
        public let localUserID: UUID
        public let durationMinutes: Int
        public let endTime: Date
        public let side: BreastSide?
        public let membership: Membership

        public init(
            eventID: UUID,
            localUserID: UUID,
            durationMinutes: Int,
            endTime: Date,
            side: BreastSide?,
            membership: Membership
        ) {
            self.eventID = eventID
            self.localUserID = localUserID
            self.durationMinutes = durationMinutes
            self.endTime = endTime
            self.side = side
            self.membership = membership
        }
    }

    private let eventRepository: any EventRepository

    public init(eventRepository: any EventRepository) {
        self.eventRepository = eventRepository
    }

    public func execute(_ input: Input) throws -> Void {
        guard ChildAccessPolicy.canPerform(.editEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        guard let event = try eventRepository.loadEvent(id: input.eventID),
              case let .breastFeed(feed) = event else {
            return
        }

        let updatedEvent = try feed.updating(
            durationMinutes: input.durationMinutes,
            endTime: input.endTime,
            side: input.side,
            updatedBy: input.localUserID
        )
        try eventRepository.saveEvent(.breastFeed(updatedEvent))
    }
}
