import Foundation

@MainActor
public struct LogBathUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let localUserID: UUID
        public let occurredAt: Date
        public let usedShampoo: Bool
        public let usedSoap: Bool
        public let membership: Membership

        public init(
            childID: UUID,
            localUserID: UUID,
            occurredAt: Date,
            usedShampoo: Bool,
            usedSoap: Bool,
            membership: Membership
        ) {
            self.childID = childID
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

    public func execute(_ input: Input) throws -> BabyEvent {
        guard ChildAccessPolicy.canPerform(.logEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        let event = BathEvent(
            metadata: EventMetadata(
                childID: input.childID,
                occurredAt: input.occurredAt,
                createdAt: .now,
                createdBy: input.localUserID
            ),
            usedShampoo: input.usedShampoo,
            usedSoap: input.usedSoap
        )

        try eventRepository.saveEvent(.bath(event))
        hapticFeedbackProvider.play(.actionSucceeded)
        return .bath(event)
    }
}
