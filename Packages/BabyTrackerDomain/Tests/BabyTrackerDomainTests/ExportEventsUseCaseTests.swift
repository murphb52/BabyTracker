import XCTest
@testable import BabyTrackerDomain

final class ExportEventsUseCaseTests: XCTestCase {
    @MainActor
    func testExportAlwaysIncludesChildProfileAndVersionOne() throws {
        let eventRepository = StubEventRepository()
        let useCase = ExportEventsUseCase(
            eventRepository: eventRepository,
            hapticFeedbackProvider: NoOpHapticFeedbackProvider()
        )
        let owner = try UserIdentity(displayName: "Alex")
        let child = try Child(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            name: "Robin",
            birthDate: Date(timeIntervalSince1970: 1_234),
            createdBy: owner.id
        )
        let membership = Membership.owner(childID: child.id, userID: owner.id, createdAt: child.createdAt)

        let data = try useCase.execute(.init(child: child, membership: membership))

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(NestExportData.self, from: data)

        XCTAssertEqual(exportData.version, 1)
        XCTAssertEqual(exportData.child.id, child.id)
        XCTAssertEqual(exportData.child.name, child.name)
        XCTAssertEqual(exportData.child.birthDate, child.birthDate)
        XCTAssertTrue(exportData.events.isEmpty)
    }

    @MainActor
    func testExportIncludesBathEvents() throws {
        let owner = try UserIdentity(displayName: "Alex")
        let child = try Child(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            name: "Robin",
            birthDate: nil,
            createdBy: owner.id
        )
        let bathTime = Date(timeIntervalSince1970: 2_345)
        let bath = BathEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: bathTime,
                createdAt: bathTime,
                createdBy: owner.id
            ),
            usedShampoo: true,
            usedSoap: false
        )
        let eventRepository = StubEventRepository(events: [.bath(bath)])
        let useCase = ExportEventsUseCase(
            eventRepository: eventRepository,
            hapticFeedbackProvider: NoOpHapticFeedbackProvider()
        )
        let membership = Membership.owner(childID: child.id, userID: owner.id, createdAt: child.createdAt)

        let data = try useCase.execute(.init(child: child, membership: membership))

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(NestExportData.self, from: data)

        guard case let .bath(exportedBath)? = exportData.events.first else {
            return XCTFail("Expected first exported event to be a bath")
        }

        XCTAssertEqual(exportedBath.occurredAt, bathTime)
        XCTAssertTrue(exportedBath.usedShampoo)
        XCTAssertFalse(exportedBath.usedSoap)
    }
}

@MainActor
private final class StubEventRepository: EventRepository {
    private let events: [BabyEvent]

    init(events: [BabyEvent] = []) {
        self.events = events
    }

    func saveEvent(_ event: BabyEvent) throws {}
    func loadEvent(id: UUID) throws -> BabyEvent? { nil }
    func loadTimeline(for childID: UUID, includingDeleted: Bool) throws -> [BabyEvent] { events }
    func loadEvents(for childID: UUID, on day: Date, calendar: Calendar, includingDeleted: Bool) throws -> [BabyEvent] { [] }
    func loadActiveSleepEvent(for childID: UUID) throws -> SleepEvent? { nil }
    func softDeleteEvent(id: UUID, deletedAt: Date, deletedBy: UUID) throws {}
}
