import Foundation

@MainActor
public struct StartSleepUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let localUserID: UUID
        public let startedAt: Date
        public let membership: Membership

        public init(childID: UUID, localUserID: UUID, startedAt: Date, membership: Membership) {
            self.childID = childID
            self.localUserID = localUserID
            self.startedAt = startedAt
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
        guard try eventRepository.loadActiveSleepEvent(for: input.childID) == nil else {
            throw BabyEventError.activeSleepAlreadyInProgress
        }

        let event = try SleepEvent(
            metadata: EventMetadata(
                childID: input.childID,
                occurredAt: input.startedAt,
                createdAt: .now,
                createdBy: input.localUserID
            ),
            startedAt: input.startedAt,
            endedAt: nil
        )

        try eventRepository.saveEvent(.sleep(event))
        return .sleep(event)
    }
}
