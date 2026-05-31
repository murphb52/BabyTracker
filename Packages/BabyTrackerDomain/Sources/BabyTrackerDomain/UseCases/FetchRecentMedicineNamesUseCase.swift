import Foundation

/// Returns the distinct medicine names previously logged for a child, most-recent first.
/// Used to build quick-pick chips in the medication editor alongside the seeded catalog.
@MainActor
public struct FetchRecentMedicineNamesUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let limit: Int

        public init(childID: UUID, limit: Int = 8) {
            self.childID = childID
            self.limit = limit
        }
    }

    private let eventRepository: any EventRepository

    public init(eventRepository: any EventRepository) {
        self.eventRepository = eventRepository
    }

    public func execute(_ input: Input) throws -> [String] {
        let timeline = try eventRepository.loadTimeline(for: input.childID, includingDeleted: false)

        let medications = timeline
            .compactMap { event -> MedicationEvent? in
                guard case let .medication(medication) = event else { return nil }
                return medication
            }
            .sorted { $0.metadata.occurredAt > $1.metadata.occurredAt }

        var seen = Set<String>()
        var names: [String] = []
        for medication in medications {
            let key = medication.medicineName.lowercased()
            guard seen.insert(key).inserted else { continue }
            names.append(medication.medicineName)
            if names.count >= input.limit { break }
        }
        return names
    }
}
