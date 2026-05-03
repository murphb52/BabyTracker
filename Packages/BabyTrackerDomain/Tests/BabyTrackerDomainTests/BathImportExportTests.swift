import XCTest
@testable import BabyTrackerDomain

final class BathImportExportTests: XCTestCase {
    func testNestJSONParserParsesBathEventsFromExportData() throws {
        let occurredAt = Date(timeIntervalSince1970: 12_345)
        let exportData = NestExportData(
            exportedAt: Date(timeIntervalSince1970: 20_000),
            child: NestChildExport(
                id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
                name: "Robin",
                birthDate: nil
            ),
            events: [
                .bath(NestBathExport(
                    id: UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!,
                    occurredAt: occurredAt,
                    notes: "Warm bath",
                    usedShampoo: true,
                    usedSoap: false
                ))
            ]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)

        let result = NestJSONParser().parse(data: data)

        XCTAssertEqual(result.skippedCount, 0)
        XCTAssertEqual(result.events.count, 1)

        guard case let .bath(bath)? = result.events.first else {
            return XCTFail("Expected parsed event to be a bath")
        }

        XCTAssertEqual(bath.metadata.occurredAt, occurredAt)
        XCTAssertEqual(bath.metadata.notes, "Warm bath")
        XCTAssertTrue(bath.usedShampoo)
        XCTAssertFalse(bath.usedSoap)
    }

    @MainActor
    func testImportChildWithEventsRestoresBathEvents() async throws {
        let localUser = try UserIdentity(displayName: "Alex")
        let occurredAt = Date(timeIntervalSince1970: 54_321)
        let exportData = NestExportData(
            exportedAt: Date(timeIntervalSince1970: 60_000),
            child: NestChildExport(
                id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
                name: "Robin",
                birthDate: Date(timeIntervalSince1970: 1_000)
            ),
            events: [
                .bath(NestBathExport(
                    id: UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!,
                    occurredAt: occurredAt,
                    notes: "Night bath",
                    usedShampoo: true,
                    usedSoap: true
                ))
            ]
        )

        let childRepository = BathImportChildRepository()
        let membershipRepository = BathImportMembershipRepository()
        let childSelectionStore = BathImportChildSelectionStore()
        let eventRepository = BathImportEventRepository()
        let useCase = ImportChildWithEventsUseCase(
            childRepository: childRepository,
            membershipRepository: membershipRepository,
            childSelectionStore: childSelectionStore,
            eventRepository: eventRepository,
            hapticFeedbackProvider: NoOpHapticFeedbackProvider()
        )

        let output = try await useCase.execute(.init(exportData: exportData, localUser: localUser))

        XCTAssertEqual(output.child.name, "Robin")
        XCTAssertEqual(output.child.birthDate, exportData.child.birthDate)
        XCTAssertEqual(output.importResult.importedCount, 1)
        XCTAssertEqual(output.importResult.skippedSaveCount, 0)
        XCTAssertEqual(childSelectionStore.selectedChildID, output.child.id)
        XCTAssertEqual(childRepository.savedChildren.count, 1)
        XCTAssertEqual(membershipRepository.savedMemberships.count, 1)
        XCTAssertEqual(eventRepository.savedEvents.count, 1)

        guard case let .bath(bath)? = eventRepository.savedEvents.first else {
            return XCTFail("Expected restored event to be a bath")
        }

        XCTAssertEqual(bath.metadata.childID, output.child.id)
        XCTAssertEqual(bath.metadata.occurredAt, occurredAt)
        XCTAssertTrue(bath.usedShampoo)
        XCTAssertTrue(bath.usedSoap)
    }
}

@MainActor
private final class BathImportChildRepository: ChildRepository {
    private(set) var savedChildren: [Child] = []

    func loadAllChildren() throws -> [Child] { [] }
    func loadActiveChildren(for userID: UUID) throws -> [Child] { [] }
    func loadArchivedChildren(for userID: UUID) throws -> [Child] { [] }
    func loadChild(id: UUID) throws -> Child? { savedChildren.first(where: { $0.id == id }) }

    func saveChild(_ child: Child) throws {
        savedChildren.append(child)
    }

    func purgeChildData(id: UUID) throws {}
}

@MainActor
private final class BathImportMembershipRepository: MembershipRepository {
    private(set) var savedMemberships: [Membership] = []

    func loadMemberships(for childID: UUID) throws -> [Membership] {
        savedMemberships.filter { $0.childID == childID }
    }

    func saveMembership(_ membership: Membership) throws {
        savedMemberships.append(membership)
    }
}

@MainActor
private final class BathImportChildSelectionStore: ChildSelectionStore {
    private(set) var selectedChildID: UUID?

    func loadSelectedChildID() -> UUID? {
        selectedChildID
    }

    func saveSelectedChildID(_ childID: UUID?) {
        selectedChildID = childID
    }
}

@MainActor
private final class BathImportEventRepository: EventRepository {
    private(set) var savedEvents: [BabyEvent] = []

    func saveEvent(_ event: BabyEvent) throws {
        savedEvents.append(event)
    }

    func loadEvent(id: UUID) throws -> BabyEvent? {
        savedEvents.first(where: { $0.id == id })
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
