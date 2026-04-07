import Foundation

@MainActor
public struct StartBreastFeedUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let localUserID: UUID
        public let startedAt: Date
        public let side: BreastSide?
        public let membership: Membership

        public init(
            childID: UUID,
            localUserID: UUID,
            startedAt: Date,
            side: BreastSide?,
            membership: Membership
        ) {
            self.childID = childID
            self.localUserID = localUserID
            self.startedAt = startedAt
            self.side = side
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

        guard try eventRepository.loadActiveBreastFeedEvent(for: input.childID) == nil else {
            throw BabyEventError.activeBreastFeedAlreadyInProgress
        }

        let event = try BreastFeedEvent(
            metadata: EventMetadata(
                childID: input.childID,
                occurredAt: input.startedAt,
                createdAt: .now,
                createdBy: input.localUserID
            ),
            side: input.side,
            startedAt: input.startedAt,
            endedAt: nil,
            leftDurationSeconds: nil,
            rightDurationSeconds: nil
        )

        try eventRepository.saveEvent(.breastFeed(event))
        hapticFeedbackProvider.play(.actionSucceeded)
        return .breastFeed(event)
    }
}
