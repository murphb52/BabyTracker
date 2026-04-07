import Foundation

@MainActor
public struct EndBreastFeedUseCase: UseCase {
    public struct Input {
        public let eventID: UUID
        public let localUserID: UUID
        public let startedAt: Date
        public let endedAt: Date
        public let side: BreastSide?
        public let leftDurationSeconds: Int?
        public let rightDurationSeconds: Int?
        public let membership: Membership

        public init(
            eventID: UUID,
            localUserID: UUID,
            startedAt: Date,
            endedAt: Date,
            side: BreastSide?,
            leftDurationSeconds: Int? = nil,
            rightDurationSeconds: Int? = nil,
            membership: Membership
        ) {
            self.eventID = eventID
            self.localUserID = localUserID
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.side = side
            self.leftDurationSeconds = leftDurationSeconds
            self.rightDurationSeconds = rightDurationSeconds
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
        guard ChildAccessPolicy.canPerform(.logEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        guard let event = try eventRepository.loadEvent(id: input.eventID) else {
            throw BabyEventError.noActiveBreastFeedInProgress
        }
        guard case let .breastFeed(feedEvent) = event, feedEvent.endedAt == nil else {
            throw BabyEventError.noActiveBreastFeedInProgress
        }

        var metadata = feedEvent.metadata
        metadata.occurredAt = input.endedAt
        metadata.markUpdated(at: .now, by: input.localUserID)

        let updatedEvent = try BreastFeedEvent(
            metadata: metadata,
            side: input.side,
            startedAt: input.startedAt,
            endedAt: input.endedAt,
            leftDurationSeconds: input.leftDurationSeconds,
            rightDurationSeconds: input.rightDurationSeconds
        )

        try eventRepository.saveEvent(.breastFeed(updatedEvent))
        hapticFeedbackProvider.play(.actionSucceeded)
        return .breastFeed(updatedEvent)
    }
}
