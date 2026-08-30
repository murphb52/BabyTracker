import Foundation

@MainActor
public struct UpdateFoodUseCase: UseCase {
    public struct Input {
        public let eventID: UUID
        public let localUserID: UUID
        public let occurredAt: Date
        public let foodName: String
        public let amount: Double
        public let unit: FoodUnit
        public let customUnitLabel: String?
        public let membership: Membership

        public init(eventID: UUID, localUserID: UUID, occurredAt: Date, foodName: String, amount: Double, unit: FoodUnit, customUnitLabel: String?, membership: Membership) {
            self.eventID = eventID
            self.localUserID = localUserID
            self.occurredAt = occurredAt
            self.foodName = foodName
            self.amount = amount
            self.unit = unit
            self.customUnitLabel = customUnitLabel
            self.membership = membership
        }
    }

    private let eventRepository: any EventRepository
    private let hapticFeedbackProvider: any HapticFeedbackProviding

    public init(eventRepository: any EventRepository, hapticFeedbackProvider: any HapticFeedbackProviding = NoOpHapticFeedbackProvider()) {
        self.eventRepository = eventRepository
        self.hapticFeedbackProvider = hapticFeedbackProvider
    }

    public func execute(_ input: Input) throws {
        guard ChildAccessPolicy.canPerform(.editEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        guard let event = try eventRepository.loadEvent(id: input.eventID), case let .food(food) = event else { return }
        let updated = try food.updating(
            occurredAt: input.occurredAt,
            foodName: input.foodName,
            amount: input.amount,
            unit: input.unit,
            customUnitLabel: input.customUnitLabel,
            updatedBy: input.localUserID
        )
        try eventRepository.saveEvent(.food(updated))
        hapticFeedbackProvider.play(.actionSucceeded)
    }
}
