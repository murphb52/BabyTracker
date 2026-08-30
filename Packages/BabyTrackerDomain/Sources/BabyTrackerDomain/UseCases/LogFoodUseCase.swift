import Foundation

@MainActor
public struct LogFoodUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let localUserID: UUID
        public let occurredAt: Date
        public let foodName: String
        public let amount: Double
        public let unit: FoodUnit
        public let customUnitLabel: String?
        public let membership: Membership

        public init(childID: UUID, localUserID: UUID, occurredAt: Date, foodName: String, amount: Double, unit: FoodUnit, customUnitLabel: String?, membership: Membership) {
            self.childID = childID
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

    public func execute(_ input: Input) throws -> BabyEvent {
        guard ChildAccessPolicy.canPerform(.logEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        let food = try FoodEvent(
            metadata: EventMetadata(childID: input.childID, occurredAt: input.occurredAt, createdBy: input.localUserID),
            foodName: input.foodName,
            amount: input.amount,
            unit: input.unit,
            customUnitLabel: input.customUnitLabel
        )
        try eventRepository.saveEvent(.food(food))
        hapticFeedbackProvider.play(.actionSucceeded)
        return .food(food)
    }
}
