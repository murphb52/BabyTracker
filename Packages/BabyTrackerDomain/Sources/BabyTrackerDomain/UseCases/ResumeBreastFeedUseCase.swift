import Foundation

@MainActor
public struct ResumeBreastFeedUseCase: UseCase {
    public struct Input {
        public let eventID: UUID
        public let localUserID: UUID
        public let startedAt: Date
        public let membership: Membership

        public init(
            eventID: UUID,
            localUserID: UUID,
            startedAt: Date,
            membership: Membership
        ) {
            self.eventID = eventID
            self.localUserID = localUserID
            self.startedAt = startedAt
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

    public func execute(_ input: Input) throws -> BabyEvent {
        guard ChildAccessPolicy.canPerform(.editEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        guard let event = try eventRepository.loadEvent(id: input.eventID) else {
            throw BabyEventError.noActiveBreastFeedInProgress
        }
        guard case let .breastFeed(feedEvent) = event else {
            throw BabyEventError.noActiveBreastFeedInProgress
        }
        guard feedEvent.endedAt != nil else {
            throw BabyEventError.breastFeedAlreadyActive
        }

        var metadata = feedEvent.metadata
        metadata.occurredAt = input.startedAt
        metadata.markUpdated(at: .now, by: input.localUserID)

        let resumedEvent = try BreastFeedEvent(
            metadata: metadata,
            side: feedEvent.side,
            startedAt: input.startedAt,
            endedAt: nil,
            leftDurationSeconds: nil,
            rightDurationSeconds: nil
        )

        try eventRepository.saveEvent(.breastFeed(resumedEvent))
        hapticFeedbackProvider.play(.actionSucceeded)
        return .breastFeed(resumedEvent)
    }
}
