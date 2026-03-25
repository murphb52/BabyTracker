import Foundation

@MainActor
public struct UpdateBottleFeedUseCase: UseCase {
    public struct Input {
        public let eventID: UUID
        public let localUserID: UUID
        public let amountMilliliters: Int
        public let occurredAt: Date
        public let milkType: MilkType?
        public let membership: Membership

        public init(
            eventID: UUID,
            localUserID: UUID,
            amountMilliliters: Int,
            occurredAt: Date,
            milkType: MilkType?,
            membership: Membership
        ) {
            self.eventID = eventID
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

    public func execute(_ input: Input) throws -> Void {
        guard ChildAccessPolicy.canPerform(.editEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        guard let event = try eventRepository.loadEvent(id: input.eventID),
              case let .bottleFeed(feed) = event else {
            return
        }

        let updatedEvent = try feed.updating(
            amountMilliliters: input.amountMilliliters,
            occurredAt: input.occurredAt,
            milkType: input.milkType,
            updatedBy: input.localUserID
        )
        try eventRepository.saveEvent(.bottleFeed(updatedEvent))
    }
}
