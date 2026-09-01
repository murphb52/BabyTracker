import Foundation

@MainActor
public struct FetchRecentFoodNamesUseCase: UseCase {
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
        let foods = try eventRepository.loadTimeline(for: input.childID, includingDeleted: false)
            .compactMap { event -> FoodEvent? in
                guard case let .food(food) = event else { return nil }
                return food
            }
            .sorted { $0.metadata.occurredAt > $1.metadata.occurredAt }

        var seen = Set<String>()
        var names: [String] = []
        for food in foods where seen.insert(food.foodName.lowercased()).inserted {
            names.append(food.foodName)
            if names.count == input.limit { break }
        }
        return names
    }
}
