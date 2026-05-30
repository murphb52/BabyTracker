import Foundation

@MainActor
public struct LogMedicationUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let localUserID: UUID
        public let occurredAt: Date
        public let medicineName: String
        public let amount: Double
        public let unit: MedicationUnit
        public let customUnitLabel: String?
        public let membership: Membership

        public init(
            childID: UUID,
            localUserID: UUID,
            occurredAt: Date,
            medicineName: String,
            amount: Double,
            unit: MedicationUnit,
            customUnitLabel: String?,
            membership: Membership
        ) {
            self.childID = childID
            self.localUserID = localUserID
            self.occurredAt = occurredAt
            self.medicineName = medicineName
            self.amount = amount
            self.unit = unit
            self.customUnitLabel = customUnitLabel
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

        let event = try MedicationEvent(
            metadata: EventMetadata(
                childID: input.childID,
                occurredAt: input.occurredAt,
                createdAt: .now,
                createdBy: input.localUserID
            ),
            medicineName: input.medicineName,
            amount: input.amount,
            unit: input.unit,
            customUnitLabel: input.customUnitLabel
        )

        try eventRepository.saveEvent(.medication(event))
        hapticFeedbackProvider.play(.actionSucceeded)
        return .medication(event)
    }
}
