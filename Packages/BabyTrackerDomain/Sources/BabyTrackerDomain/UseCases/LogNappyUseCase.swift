import Foundation

@MainActor
public struct LogNappyUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let localUserID: UUID
        public let type: NappyType
        public let occurredAt: Date
        public let intensity: NappyIntensity?
        public let pooColor: PooColor?
        public let membership: Membership

        public init(
            childID: UUID,
            localUserID: UUID,
            type: NappyType,
            occurredAt: Date,
            intensity: NappyIntensity?,
            pooColor: PooColor?,
            membership: Membership
        ) {
            self.childID = childID
            self.localUserID = localUserID
            self.type = type
            self.occurredAt = occurredAt
            self.intensity = intensity
            self.pooColor = pooColor
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

        let event = try NappyEvent(
            metadata: EventMetadata(
                childID: input.childID,
                occurredAt: input.occurredAt,
                createdAt: .now,
                createdBy: input.localUserID
            ),
            type: input.type,
            intensity: input.intensity,
            pooColor: input.pooColor
        )

        try eventRepository.saveEvent(.nappy(event))
        return .nappy(event)
    }
}
