import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct MedicationUseCaseTests {
    @Test
    func logMedicationPersistsEvent() throws {
        let childID = UUID()
        let userID = UUID()
        let repository = StubMedicationEventRepository()
        let membership = Membership.owner(childID: childID, userID: userID)

        let event = try LogMedicationUseCase(eventRepository: repository).execute(.init(
            childID: childID,
            localUserID: userID,
            occurredAt: Date(timeIntervalSince1970: 1_000),
            medicineName: "Calpol",
            amount: 5,
            unit: .ml,
            customUnitLabel: nil,
            membership: membership
        ))

        guard case let .medication(medication) = event else {
            Issue.record("Expected a medication event")
            return
        }
        #expect(medication.medicineName == "Calpol")
        #expect(medication.amount == 5)
        #expect(medication.unit == .ml)
        #expect(repository.savedEvents.count == 1)
    }

    @Test
    func logMedicationRejectsNonPositiveAmount() {
        let childID = UUID()
        let userID = UUID()
        let repository = StubMedicationEventRepository()
        let membership = Membership.owner(childID: childID, userID: userID)

        #expect(throws: BabyEventError.invalidMedicationAmount) {
            _ = try LogMedicationUseCase(eventRepository: repository).execute(.init(
                childID: childID,
                localUserID: userID,
                occurredAt: Date(),
                medicineName: "Calpol",
                amount: 0,
                unit: .ml,
                customUnitLabel: nil,
                membership: membership
            ))
        }
    }

    @Test
    func logMedicationRejectsEmptyName() {
        let childID = UUID()
        let userID = UUID()
        let repository = StubMedicationEventRepository()
        let membership = Membership.owner(childID: childID, userID: userID)

        #expect(throws: BabyEventError.invalidMedicationName) {
            _ = try LogMedicationUseCase(eventRepository: repository).execute(.init(
                childID: childID,
                localUserID: userID,
                occurredAt: Date(),
                medicineName: "   ",
                amount: 5,
                unit: .ml,
                customUnitLabel: nil,
                membership: membership
            ))
        }
    }

    @Test
    func updateMedicationModifiesStoredEvent() throws {
        let childID = UUID()
        let userID = UUID()
        let repository = StubMedicationEventRepository()
        let membership = Membership.owner(childID: childID, userID: userID)

        let logged = try LogMedicationUseCase(eventRepository: repository).execute(.init(
            childID: childID,
            localUserID: userID,
            occurredAt: Date(timeIntervalSince1970: 1_000),
            medicineName: "Calpol",
            amount: 5,
            unit: .ml,
            customUnitLabel: nil,
            membership: membership
        ))

        try UpdateMedicationUseCase(eventRepository: repository).execute(.init(
            eventID: logged.id,
            localUserID: userID,
            occurredAt: Date(timeIntervalSince1970: 2_000),
            medicineName: "Nurofen",
            amount: 2.5,
            unit: .custom,
            customUnitLabel: "sachet",
            membership: membership
        ))

        guard case let .medication(updated)? = try repository.loadEvent(id: logged.id) else {
            Issue.record("Expected a medication event")
            return
        }
        #expect(updated.medicineName == "Nurofen")
        #expect(updated.amount == 2.5)
        #expect(updated.unit == .custom)
        #expect(updated.customUnitLabel == "sachet")
    }

    @Test
    func fetchRecentMedicineNamesReturnsDistinctMostRecentFirst() throws {
        let childID = UUID()
        let userID = UUID()
        let repository = StubMedicationEventRepository()

        func make(name: String, secondsAgo: TimeInterval) throws -> BabyEvent {
            .medication(try MedicationEvent(
                metadata: EventMetadata(
                    childID: childID,
                    occurredAt: Date(timeIntervalSinceNow: -secondsAgo),
                    createdBy: userID
                ),
                medicineName: name,
                amount: 5,
                unit: .ml
            ))
        }

        try repository.saveEvent(make(name: "Calpol", secondsAgo: 30))
        try repository.saveEvent(make(name: "Nurofen", secondsAgo: 20))
        try repository.saveEvent(make(name: "calpol", secondsAgo: 10))

        let names = try FetchRecentMedicineNamesUseCase(eventRepository: repository)
            .execute(.init(childID: childID))

        // Most recent "calpol" first, then Nurofen; the older "Calpol" is de-duped case-insensitively.
        #expect(names == ["calpol", "Nurofen"])
    }
}

@MainActor
private final class StubMedicationEventRepository: EventRepository {
    private(set) var savedEvents: [BabyEvent] = []

    func saveEvent(_ event: BabyEvent) throws {
        savedEvents.removeAll { $0.id == event.id }
        savedEvents.append(event)
    }

    func loadEvent(id: UUID) throws -> BabyEvent? {
        savedEvents.first { $0.id == id }
    }

    func loadTimeline(for childID: UUID, includingDeleted: Bool) throws -> [BabyEvent] {
        savedEvents.filter { $0.metadata.childID == childID }
    }

    func loadEvents(for childID: UUID, on day: Date, calendar: Calendar, includingDeleted: Bool) throws -> [BabyEvent] {
        savedEvents.filter {
            $0.metadata.childID == childID &&
            calendar.isDate($0.metadata.occurredAt, inSameDayAs: day)
        }
    }

    func loadActiveSleepEvent(for childID: UUID) throws -> SleepEvent? { nil }
    func softDeleteEvent(id: UUID, deletedAt: Date, deletedBy: UUID) throws {}
}
