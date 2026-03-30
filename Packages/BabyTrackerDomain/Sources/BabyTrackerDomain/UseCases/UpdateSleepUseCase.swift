import Foundation

@MainActor
public struct UpdateSleepUseCase: UseCase {
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
    private let hapticFeedbackProvider: any HapticFeedbackProviding

    public init(
        eventRepository: any EventRepository,
        hapticFeedbackProvider: any HapticFeedbackProviding = NoOpHapticFeedbackProvider()
    ) {
        self.eventRepository = eventRepository
        self.hapticFeedbackProvider = hapticFeedbackProvider
    }

    public func execute(_ input: Input) throws -> Void {
        guard ChildAccessPolicy.canPerform(.editEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        guard let event = try eventRepository.loadEvent(id: input.eventID),
              case let .sleep(sleepEvent) = event,
              sleepEvent.endedAt != nil else {
            return
        }

        let updatedEvent = try sleepEvent.updating(
            startedAt: input.startedAt,
            endedAt: input.endedAt,
            updatedBy: input.localUserID
        )
        try eventRepository.saveEvent(.sleep(updatedEvent))
        hapticFeedbackProvider.play(.actionSucceeded)
    }
}
