import Foundation

/// Loads all non-deleted events for a child and serialises them into a Nest JSON export file.
@MainActor
public struct ExportEventsUseCase: UseCase {
    public struct Input {
        public let child: Child
        public let membership: Membership

        public init(child: Child, membership: Membership) {
            self.child = child
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

    public func execute(_ input: Input) throws -> Data {
        let events = try eventRepository.loadTimeline(for: input.child.id, includingDeleted: false)

        let exportEvents: [NestEventExport] = events.compactMap { nestEvent(from: $0) }

        let exportData = NestExportData(
            exportedAt: Date(),
            child: NestChildExport(
                id: input.child.id,
                name: input.child.name,
                birthDate: input.child.birthDate
            ),
            events: exportEvents
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(exportData)
        hapticFeedbackProvider.play(.actionSucceeded)
        return data
    }

    // MARK: - Mapping

    private func nestEvent(from event: BabyEvent) -> NestEventExport? {
        switch event {
        case .breastFeed(let e):
            return .breastFeed(NestBreastFeedExport(
                id: e.metadata.id,
                occurredAt: e.metadata.occurredAt,
                notes: e.metadata.notes,
                side: e.side,
                startedAt: e.startedAt,
                endedAt: e.endedAt,
                leftDurationSeconds: e.leftDurationSeconds,
                rightDurationSeconds: e.rightDurationSeconds
            ))
        case .bottleFeed(let e):
            return .bottleFeed(NestBottleFeedExport(
                id: e.metadata.id,
                occurredAt: e.metadata.occurredAt,
                notes: e.metadata.notes,
                amountMilliliters: e.amountMilliliters,
                milkType: e.milkType
            ))
        case .sleep(let e):
            guard let endedAt = e.endedAt else {
                // Skip in-progress sleep sessions — they have no end time
                return nil
            }
            return .sleep(NestSleepExport(
                id: e.metadata.id,
                occurredAt: e.metadata.occurredAt,
                notes: e.metadata.notes,
                startedAt: e.startedAt,
                endedAt: endedAt
            ))
        case .nappy(let e):
            return .nappy(NestNappyExport(
                id: e.metadata.id,
                occurredAt: e.metadata.occurredAt,
                notes: e.metadata.notes,
                nappyType: e.type,
                peeVolume: e.peeVolume,
                pooVolume: e.pooVolume,
                pooColor: e.pooColor
            ))
        }
    }
}
