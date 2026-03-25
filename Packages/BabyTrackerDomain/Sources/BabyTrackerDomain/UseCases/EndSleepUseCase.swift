import Foundation

@MainActor
public struct EndSleepUseCase: UseCase {
    public struct Input {
        public let eventID: UUID
        public let localUserID: UUID
        public let startedAt: Date
        public let endedAt: Date
        public let membership: Membership

        public init(
            eventID: UUID,
            localUserID: UUID,
            startedAt: Date,
            endedAt: Date,
            membership: Membership
        ) {
            self.eventID = eventID
            self.localUserID = localUserID
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.membership = membership
        }
    }

    private let eventRepository: any EventRepository

    public init(eventRepository: any EventRepository) {
        self.eventRepository = eventRepository
    }

    public func execute(_ input: Input) throws -> BabyEvent {
        guard ChildAccessPolicy.canPerform(.logEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        guard let event = try eventRepository.loadEvent(id: input.eventID) else {
            throw BabyEventError.noActiveSleepInProgress
        }
        guard case let .sleep(sleepEvent) = event, sleepEvent.endedAt == nil else {
            throw BabyEventError.noActiveSleepInProgress
        }

        let updatedEvent = try sleepEvent.updating(
            startedAt: input.startedAt,
            endedAt: input.endedAt,
            updatedBy: input.localUserID
        )

        try eventRepository.saveEvent(.sleep(updatedEvent))
        return .sleep(updatedEvent)
    }
}
