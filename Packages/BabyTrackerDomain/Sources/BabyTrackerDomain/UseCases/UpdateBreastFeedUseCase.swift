import Foundation

@MainActor
public struct UpdateBreastFeedUseCase: UseCase {
    public struct Input {
        public let eventID: UUID
        public let localUserID: UUID
        public let durationMinutes: Int
        public let endTime: Date
        public let side: BreastSide?
        public let leftDurationSeconds: Int?
        public let rightDurationSeconds: Int?
        public let membership: Membership

        public init(
            eventID: UUID,
            localUserID: UUID,
            durationMinutes: Int,
            endTime: Date,
            side: BreastSide?,
            leftDurationSeconds: Int? = nil,
            rightDurationSeconds: Int? = nil,
            membership: Membership
        ) {
            self.eventID = eventID
            self.localUserID = localUserID
            self.durationMinutes = durationMinutes
            self.endTime = endTime
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
            leftDurationSeconds: input.leftDurationSeconds,
            rightDurationSeconds: input.rightDurationSeconds,
            updatedBy: input.localUserID
        )
        try eventRepository.saveEvent(.breastFeed(updatedEvent))
        hapticFeedbackProvider.play(.actionSucceeded)
    }
}
