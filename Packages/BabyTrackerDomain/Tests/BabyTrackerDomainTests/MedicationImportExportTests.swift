import XCTest
@testable import BabyTrackerDomain

final class MedicationImportExportTests: XCTestCase {
    func testNestJSONRoundTripsMedicationWithCustomUnit() throws {
        let occurredAt = Date(timeIntervalSince1970: 12_345)
        let exportData = NestExportData(
            exportedAt: Date(timeIntervalSince1970: 20_000),
            child: NestChildExport(
                id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
                name: "Robin",
                birthDate: nil
            ),
            events: [
                .medication(NestMedicationExport(
                    id: UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!,
                    occurredAt: occurredAt,
                    notes: "After lunch",
                    medicineName: "Calpol",
                    amount: 2.5,
                    unit: .custom,
                    customUnitLabel: "puff"
                ))
            ]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)

        let result = NestJSONParser().parse(data: data)

        XCTAssertEqual(result.skippedCount, 0)
        XCTAssertEqual(result.events.count, 1)

        guard case let .medication(medication)? = result.events.first else {
            return XCTFail("Expected parsed event to be a medication")
        }

        XCTAssertEqual(medication.metadata.occurredAt, occurredAt)
        XCTAssertEqual(medication.metadata.notes, "After lunch")
        XCTAssertEqual(medication.medicineName, "Calpol")
        XCTAssertEqual(medication.amount, 2.5)
        XCTAssertEqual(medication.unit, .custom)
        XCTAssertEqual(medication.customUnitLabel, "puff")
    }

    func testNestJSONParserSkipsMedicationWithNonPositiveAmount() throws {
        let exportData = NestExportData(
            exportedAt: Date(timeIntervalSince1970: 20_000),
            child: NestChildExport(id: UUID(), name: "Robin", birthDate: nil),
            events: [
                .medication(NestMedicationExport(
                    id: UUID(),
                    occurredAt: Date(timeIntervalSince1970: 1_000),
                    notes: "",
                    medicineName: "Calpol",
                    amount: 0,
                    unit: .ml,
                    customUnitLabel: nil
                ))
            ]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)

        let result = NestJSONParser().parse(data: data)

        XCTAssertEqual(result.events.count, 0)
        XCTAssertEqual(result.skippedCount, 1)
    }

    @MainActor
    func testExportEventsUseCaseEncodesMedication() throws {
        let childID = UUID()
        let userID = UUID()
        let child = try Child(name: "Robin", createdBy: userID)
        let medication = try MedicationEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: Date(timeIntervalSince1970: 5_000),
                createdAt: Date(timeIntervalSince1970: 5_000),
                createdBy: userID
            ),
            medicineName: "Vitamin D drops",
            amount: 1,
            unit: .drops
        )

        let repository = MedicationStubEventRepository(events: [.medication(medication)])
        let data = try ExportEventsUseCase(eventRepository: repository)
            .execute(.init(child: child, membership: Membership.owner(childID: child.id, userID: userID, createdAt: Date())))

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(NestExportData.self, from: data)

        XCTAssertEqual(decoded.events.count, 1)
        guard case let .medication(exported)? = decoded.events.first else {
            return XCTFail("Expected exported event to be a medication")
        }
        XCTAssertEqual(exported.medicineName, "Vitamin D drops")
        XCTAssertEqual(exported.amount, 1)
        XCTAssertEqual(exported.unit, .drops)

        _ = childID
    }
}

@MainActor
private final class MedicationStubEventRepository: EventRepository {
    private var events: [BabyEvent]

    init(events: [BabyEvent]) {
        self.events = events
    }

    func saveEvent(_ event: BabyEvent) throws {
        events.removeAll { $0.id == event.id }
        events.append(event)
    }

    func loadEvent(id: UUID) throws -> BabyEvent? {
        events.first { $0.id == id }
    }

    func loadTimeline(for childID: UUID, includingDeleted: Bool) throws -> [BabyEvent] {
        events.filter { $0.metadata.childID == childID }
    }

    func loadEvents(for childID: UUID, on day: Date, calendar: Calendar, includingDeleted: Bool) throws -> [BabyEvent] {
        events.filter {
            $0.metadata.childID == childID &&
            calendar.isDate($0.metadata.occurredAt, inSameDayAs: day)
        }
    }

    func loadActiveSleepEvent(for childID: UUID) throws -> SleepEvent? { nil }
    func softDeleteEvent(id: UUID, deletedAt: Date, deletedBy: UUID) throws {}
}
