import Foundation

/// Saves a batch of parsed CSV events for a specific child.
/// Reuses existing `Log*UseCase` types to ensure consistent validation and persistence.
///
/// This is a long-running batch operation, not an atomic action, so it does not conform
/// to `UseCase`. It is async and reports progress incrementally via `onProgress`.
@MainActor
public struct ImportEventsUseCase {
    public struct Input {
        public let events: [ImportableEvent]
        public let childID: UUID
        public let localUserID: UUID
        public let membership: Membership

        public init(
            events: [ImportableEvent],
            childID: UUID,
            localUserID: UUID,
            membership: Membership
        ) {
            self.events = events
            self.childID = childID
            self.localUserID = localUserID
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

    /// - Parameters:
    ///   - input: The batch of events to save.
    ///   - onProgress: Called periodically with (completed, total) so the caller can update UI.
    public func execute(_ input: Input, onProgress: ((Int, Int) -> Void)? = nil) async throws -> CSVImportResult {
        guard ChildAccessPolicy.canPerform(.logEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        let total = input.events.count
        var importedCount = 0
        var skippedReasons: [String] = []

        for (index, event) in input.events.enumerated() {
            do {
                try save(event, childID: input.childID, localUserID: input.localUserID, membership: input.membership)
                importedCount += 1
            } catch {
                skippedReasons.append("\(event.eventKindLabel) at \(event.occurredAt.formatted()): \(error.localizedDescription)")
            }

            // Yield periodically so the run loop can process UI updates.
            if index % 20 == 19 {
                onProgress?(index + 1, total)
                await Task.yield()
            }
        }

        onProgress?(total, total)

        if importedCount > 0 {
            hapticFeedbackProvider.play(.actionSucceeded)
        }

        return CSVImportResult(
            importedCount: importedCount,
            skippedParseCount: 0,
            skippedSaveCount: skippedReasons.count,
            skippedReasons: skippedReasons
        )
    }

    // MARK: - Per-event save

    private func save(_ event: ImportableEvent, childID: UUID, localUserID: UUID, membership: Membership) throws {
        switch event {
        case .bottleFeed(let e):
            try saveBottleFeed(e, childID: childID, localUserID: localUserID, membership: membership)
        case .breastFeed(let e):
            try saveBreastFeed(e, childID: childID, localUserID: localUserID, membership: membership)
        case .sleep(let e):
            try saveSleep(e, childID: childID, localUserID: localUserID, membership: membership)
        case .nappy(let e):
            try saveNappy(e, childID: childID, localUserID: localUserID, membership: membership)
        }
    }

    private func saveBottleFeed(
        _ e: BottleFeedImport,
        childID: UUID,
        localUserID: UUID,
        membership: Membership
    ) throws {
        _ = try LogBottleFeedUseCase(
            eventRepository: eventRepository,
            hapticFeedbackProvider: NoOpHapticFeedbackProvider()
        )
            .execute(.init(
                childID: childID,
                localUserID: localUserID,
                amountMilliliters: e.amountMilliliters,
                occurredAt: e.metadata.occurredAt,
                milkType: e.milkType,
                membership: membership
            ))
    }

    private func saveBreastFeed(
        _ e: BreastFeedImport,
        childID: UUID,
        localUserID: UUID,
        membership: Membership
    ) throws {
        _ = try LogBreastFeedUseCase(
            eventRepository: eventRepository,
            hapticFeedbackProvider: NoOpHapticFeedbackProvider()
        )
            .execute(.init(
                childID: childID,
                localUserID: localUserID,
                durationMinutes: e.durationMinutes,
                endTime: e.endedAt,
                side: e.side,
                leftDurationSeconds: e.leftDurationSeconds,
                rightDurationSeconds: e.rightDurationSeconds,
                membership: membership
            ))
    }

    private func saveSleep(
        _ e: SleepImport,
        childID: UUID,
        localUserID: UUID,
        membership: Membership
    ) throws {
        _ = try LogSleepUseCase(
            eventRepository: eventRepository,
            hapticFeedbackProvider: NoOpHapticFeedbackProvider()
        )
            .execute(.init(
                childID: childID,
                localUserID: localUserID,
                startedAt: e.startedAt,
                endedAt: e.endedAt,
                membership: membership
            ))
    }

    private func saveNappy(
        _ e: NappyImport,
        childID: UUID,
        localUserID: UUID,
        membership: Membership
    ) throws {
        _ = try LogNappyUseCase(
            eventRepository: eventRepository,
            hapticFeedbackProvider: NoOpHapticFeedbackProvider()
        )
            .execute(.init(
                childID: childID,
                localUserID: localUserID,
                type: e.type,
                occurredAt: e.metadata.occurredAt,
                peeVolume: e.peeVolume,
                pooVolume: e.pooVolume,
                pooColor: e.pooColor,
                membership: membership
            ))
    }
}
