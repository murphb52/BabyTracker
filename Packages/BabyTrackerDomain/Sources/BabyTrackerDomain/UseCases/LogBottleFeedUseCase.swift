import Foundation

@MainActor
public struct LogBottleFeedUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let localUserID: UUID
        public let amountMilliliters: Int
        public let occurredAt: Date
        public let milkType: MilkType?
        public let membership: Membership

        public init(
            childID: UUID,
            localUserID: UUID,
            amountMilliliters: Int,
            occurredAt: Date,
            milkType: MilkType?,
            membership: Membership
        ) {
            self.childID = childID
            self.localUserID = localUserID
            self.amountMilliliters = amountMilliliters
            self.occurredAt = occurredAt
            self.milkType = milkType
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

        let event = try BottleFeedEvent(
            metadata: EventMetadata(
                childID: input.childID,
                occurredAt: input.occurredAt,
                createdAt: .now,
                createdBy: input.localUserID
            ),
            amountMilliliters: input.amountMilliliters,
            milkType: input.milkType
        )

        try eventRepository.saveEvent(.bottleFeed(event))
        return .bottleFeed(event)
    }
}
