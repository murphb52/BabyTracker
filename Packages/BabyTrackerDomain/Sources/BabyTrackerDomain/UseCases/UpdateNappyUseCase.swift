import Foundation

@MainActor
public struct UpdateNappyUseCase: UseCase {
    public struct Input {
        public let eventID: UUID
        public let localUserID: UUID
        public let type: NappyType
        public let occurredAt: Date
        public let peeVolume: NappyVolume?
        public let pooVolume: NappyVolume?
        public let pooColor: PooColor?
        public let membership: Membership

        public init(
            eventID: UUID,
            localUserID: UUID,
            type: NappyType,
            occurredAt: Date,
            peeVolume: NappyVolume?,
            pooVolume: NappyVolume?,
            pooColor: PooColor?,
            membership: Membership
        ) {
            self.eventID = eventID
            self.localUserID = localUserID
            self.type = type
            self.occurredAt = occurredAt
            self.peeVolume = peeVolume
            self.pooVolume = pooVolume
            self.pooColor = pooColor
            self.membership = membership
        }
    }

    private let eventRepository: any EventRepository

    public init(eventRepository: any EventRepository) {
        self.eventRepository = eventRepository
    }

    public func execute(_ input: Input) throws -> Void {
        guard ChildAccessPolicy.canPerform(.editEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        guard let event = try eventRepository.loadEvent(id: input.eventID),
              case let .nappy(nappyEvent) = event else {
            return
        }

        let updatedEvent = try nappyEvent.updating(
            type: input.type,
            occurredAt: input.occurredAt,
            peeVolume: input.peeVolume,
            pooVolume: input.pooVolume,
            pooColor: input.pooColor,
            updatedBy: input.localUserID
        )
        try eventRepository.saveEvent(.nappy(updatedEvent))
    }
}
