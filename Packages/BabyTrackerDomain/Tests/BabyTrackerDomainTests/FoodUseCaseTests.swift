import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct FoodUseCaseTests {
    @Test
    func foodValidatesTrimsAndFormatsPortions() throws {
        let event = try FoodEvent(
            metadata: EventMetadata(childID: UUID(), occurredAt: .now, createdBy: UUID()),
            foodName: "  Porridge  ",
            amount: 0.5,
            unit: .bowl
        )

        #expect(event.foodName == "Porridge")
        #expect(event.displayAmount == "½ bowls")
        #expect(FoodEvent.formattedAmount(0.25) == "¼")
        #expect(FoodEvent.formattedAmount(1.5) == "1½")
    }

    @Test
    func customUnitIsRequiredAndTrimmed() throws {
        #expect(throws: BabyEventError.invalidFoodUnit) {
            _ = try FoodEvent(
                metadata: EventMetadata(childID: UUID(), occurredAt: .now, createdBy: UUID()),
                foodName: "Banana",
                amount: 1,
                unit: .custom,
                customUnitLabel: "  "
            )
        }

        let event = try FoodEvent(
            metadata: EventMetadata(childID: UUID(), occurredAt: .now, createdBy: UUID()),
            foodName: "Banana",
            amount: 1,
            unit: .custom,
            customUnitLabel: " slice "
        )
        #expect(event.displayAmount == "1 slice")
    }

    @Test
    func recentNamesAreDistinctAndMostRecentFirst() throws {
        let childID = UUID()
        let userID = UUID()
        let repository = FoodEventRepositoryStub()
        try repository.saveEvent(.food(try makeFood("Porridge", at: 100, childID: childID, userID: userID)))
        try repository.saveEvent(.food(try makeFood("Banana", at: 200, childID: childID, userID: userID)))
        try repository.saveEvent(.food(try makeFood("porridge", at: 300, childID: childID, userID: userID)))

        let names = try FetchRecentFoodNamesUseCase(eventRepository: repository).execute(.init(childID: childID))
        #expect(names == ["porridge", "Banana"])
    }

    @Test
    func exactPresetMatchIsDeduplicatedButDifferentAmountIsAllowed() throws {
        let childID = UUID()
        let userID = UUID()
        let membership = Membership.owner(childID: childID, userID: userID)
        let repository = FoodPresetRepositoryStub()
        let useCase = SaveFoodPresetUseCase(repository: repository)

        let first = try useCase.execute(.init(childID: childID, localUserID: userID, foodName: "Porridge", amount: 1, unit: .bowl, customUnitLabel: nil, membership: membership))
        let duplicate = try useCase.execute(.init(childID: childID, localUserID: userID, foodName: "porridge", amount: 1, unit: .bowl, customUnitLabel: nil, membership: membership))
        _ = try useCase.execute(.init(childID: childID, localUserID: userID, foodName: "Porridge", amount: 0.5, unit: .bowl, customUnitLabel: nil, membership: membership))

        #expect(first.id == duplicate.id)
        #expect(repository.presets.count == 2)
        #expect(repository.presets.map(\.sortOrder).sorted() == [-1, 0])
    }

    private func makeFood(_ name: String, at timestamp: TimeInterval, childID: UUID, userID: UUID) throws -> FoodEvent {
        try FoodEvent(
            metadata: EventMetadata(childID: childID, occurredAt: Date(timeIntervalSince1970: timestamp), createdBy: userID),
            foodName: name,
            amount: 1,
            unit: .bowl
        )
    }
}

@MainActor
private final class FoodEventRepositoryStub: EventRepository {
    var events: [BabyEvent] = []
    func saveEvent(_ event: BabyEvent) throws { events.append(event) }
    func loadEvent(id: UUID) throws -> BabyEvent? { events.first { $0.id == id } }
    func loadTimeline(for childID: UUID, includingDeleted: Bool) throws -> [BabyEvent] { events.filter { $0.metadata.childID == childID }.sorted { $0.metadata.occurredAt > $1.metadata.occurredAt } }
    func loadEvents(for childID: UUID, on day: Date, calendar: Calendar, includingDeleted: Bool) throws -> [BabyEvent] { [] }
    func loadActiveSleepEvent(for childID: UUID) throws -> SleepEvent? { nil }
    func softDeleteEvent(id: UUID, deletedAt: Date, deletedBy: UUID) throws {}
}

@MainActor
private final class FoodPresetRepositoryStub: FoodPresetRepository {
    var presets: [FoodPreset] = []
    func savePreset(_ preset: FoodPreset) throws { presets.removeAll { $0.id == preset.id }; presets.append(preset) }
    func loadPreset(id: UUID) throws -> FoodPreset? { presets.first { $0.id == id } }
    func loadPresets(for childID: UUID, includingDeleted: Bool) throws -> [FoodPreset] { presets.filter { $0.childID == childID && (includingDeleted || !$0.isDeleted) } }
    func softDeletePreset(id: UUID, deletedAt: Date, deletedBy: UUID) throws {}
}
