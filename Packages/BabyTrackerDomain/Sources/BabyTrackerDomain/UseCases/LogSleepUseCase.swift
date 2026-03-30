import Foundation

@MainActor
public struct LogSleepUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let localUserID: UUID
        public let startedAt: Date
        public let endedAt: Date
        public let membership: Membership

        public init(childID: UUID, localUserID: UUID, startedAt: Date, endedAt: Date, membership: Membership) {
            self.childID = childID
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

    public func execute(_ input: Input) throws -> BabyEvent {
        guard ChildAccessPolicy.canPerform(.logEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        let event = try SleepEvent(
            metadata: EventMetadata(
                childID: input.childID,
                occurredAt: input.endedAt,
                createdAt: .now,
                createdBy: input.localUserID
            ),
            startedAt: input.startedAt,
            endedAt: input.endedAt
        )

        try eventRepository.saveEvent(.sleep(event))
        hapticFeedbackProvider.play(.actionSucceeded)
        return .sleep(event)
    }
}
