import Foundation

@MainActor
public struct LogBreastFeedUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let localUserID: UUID
        public let durationMinutes: Int
        public let endTime: Date
        public let side: BreastSide?
        public let membership: Membership

        public init(
            childID: UUID,
            localUserID: UUID,
            durationMinutes: Int,
            endTime: Date,
            side: BreastSide?,
            membership: Membership
        ) {
            self.childID = childID
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

    public func execute(_ input: Input) throws -> BabyEvent {
        guard ChildAccessPolicy.canPerform(.logEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        let startedAt = input.endTime.addingTimeInterval(TimeInterval(input.durationMinutes * -60))
        let event = try BreastFeedEvent(
            metadata: EventMetadata(
                childID: input.childID,
                occurredAt: input.endTime,
                createdAt: .now,
                createdBy: input.localUserID
            ),
            side: input.side,
            startedAt: startedAt,
            endedAt: input.endTime
        )

        try eventRepository.saveEvent(.breastFeed(event))
        return .breastFeed(event)
    }
}
