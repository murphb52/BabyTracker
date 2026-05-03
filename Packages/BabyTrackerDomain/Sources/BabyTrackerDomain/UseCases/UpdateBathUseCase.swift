import Foundation

@MainActor
public struct UpdateBathUseCase: UseCase {
    public struct Input {
        public let eventID: UUID
        public let localUserID: UUID
        public let occurredAt: Date
        public let usedShampoo: Bool
        public let usedSoap: Bool
        public let membership: Membership

        public init(
            eventID: UUID,
            localUserID: UUID,
            occurredAt: Date,
            usedShampoo: Bool,
            usedSoap: Bool,
            membership: Membership
        ) {
            self.eventID = eventID
            self.localUserID = localUserID
            self.occurredAt = occurredAt
            self.usedShampoo = usedShampoo
            self.usedSoap = usedSoap
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

    public func execute(_ input: Input) throws {
        guard ChildAccessPolicy.canPerform(.editEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        guard let event = try eventRepository.loadEvent(id: input.eventID),
              case let .bath(bath) = event else {
            return
        }

        let updatedEvent = bath.updating(
            occurredAt: input.occurredAt,
            usedShampoo: input.usedShampoo,
            usedSoap: input.usedSoap,
            updatedBy: input.localUserID
        )
        try eventRepository.saveEvent(.bath(updatedEvent))
        hapticFeedbackProvider.play(.actionSucceeded)
    }
}
