import Foundation

/// Restores a full Nest backup by creating a brand-new child profile and importing all
/// events from the file under that new child.
///
/// Both the child and every event receive fresh UUIDs — the IDs in the export file are
/// never reused. This makes the use case safe to run on a device that may already have
/// data from the same original child (e.g. a second restore or a shared family device).
///
/// The export file must contain child profile data. Use ``ImportEventsUseCase`` when you
/// only need to import events into an *existing* child profile.
@MainActor
public struct ImportChildWithEventsUseCase {
    public struct Input: Sendable {
        /// A decoded Nest export that includes child profile data.
        public let exportData: NestExportData
        public let localUser: UserIdentity

        public init(exportData: NestExportData, localUser: UserIdentity) {
            self.exportData = exportData
            self.localUser = localUser
        }
    }

    public struct Output: Sendable {
        public let child: Child
        public let importResult: CSVImportResult
    }

    private let childRepository: any ChildRepository
    private let membershipRepository: any MembershipRepository
    private let childSelectionStore: any ChildSelectionStore
    private let eventRepository: any EventRepository
    private let hapticFeedbackProvider: any HapticFeedbackProviding

    public init(
        childRepository: any ChildRepository,
        membershipRepository: any MembershipRepository,
        childSelectionStore: any ChildSelectionStore,
        eventRepository: any EventRepository,
        hapticFeedbackProvider: any HapticFeedbackProviding = NoOpHapticFeedbackProvider()
    ) {
        self.childRepository = childRepository
        self.membershipRepository = membershipRepository
        self.childSelectionStore = childSelectionStore
        self.eventRepository = eventRepository
        self.hapticFeedbackProvider = hapticFeedbackProvider
    }

    public func execute(
        _ input: Input,
        onProgress: ((Int, Int) -> Void)? = nil
    ) async throws -> Output {
        // Step 1: Create a brand-new child — fresh UUID, name and birthDate carried over.
        let child = try CreateChildUseCase(
            childRepository: childRepository,
            membershipRepository: membershipRepository,
            childSelectionStore: childSelectionStore
        ).execute(.init(
            name: input.exportData.child.name,
            birthDate: input.exportData.child.birthDate,
            localUser: input.localUser
        ))

        // Step 2: Build the owner membership for the permission check inside ImportEventsUseCase.
        // CreateChildUseCase already persisted this membership; we construct the value here
        // to avoid a repository round-trip.
        let ownerMembership = Membership.owner(
            childID: child.id,
            userID: input.localUser.id,
            createdAt: child.createdAt
        )

        // Step 3: Convert NestEventExport → ImportableEvent.
        // ImportEventMetadata.init always generates a fresh UUID, so no exported IDs are reused.
        let importableEvents = input.exportData.events.compactMap { importableEvent(from: $0) }

        // Step 4: Import all events under the new child.
        let importResult = try await ImportEventsUseCase(
            eventRepository: eventRepository,
            hapticFeedbackProvider: hapticFeedbackProvider
        ).execute(
            .init(
                events: importableEvents,
                childID: child.id,
                localUserID: input.localUser.id,
                membership: ownerMembership
            ),
            onProgress: onProgress
        )

        return Output(child: child, importResult: importResult)
    }

    // MARK: - Event mapping

    private func importableEvent(from nestEvent: NestEventExport) -> ImportableEvent? {
        switch nestEvent {
        case .breastFeed(let e):
            let durationMinutes = Int(e.endedAt.timeIntervalSince(e.startedAt) / 60)
            return .breastFeed(BreastFeedImport(
                metadata: ImportEventMetadata(occurredAt: e.occurredAt, notes: e.notes.isEmpty ? nil : e.notes),
                startedAt: e.startedAt,
                endedAt: e.endedAt,
                durationMinutes: durationMinutes,
                side: e.side,
                leftDurationSeconds: e.leftDurationSeconds,
                rightDurationSeconds: e.rightDurationSeconds
            ))
        case .bottleFeed(let e):
            guard e.amountMilliliters > 0 else { return nil }
            return .bottleFeed(BottleFeedImport(
                metadata: ImportEventMetadata(occurredAt: e.occurredAt, notes: e.notes.isEmpty ? nil : e.notes),
                amountMilliliters: e.amountMilliliters,
                milkType: e.milkType
            ))
        case .sleep(let e):
            guard e.endedAt >= e.startedAt else { return nil }
            return .sleep(SleepImport(
                metadata: ImportEventMetadata(occurredAt: e.occurredAt, notes: e.notes.isEmpty ? nil : e.notes),
                startedAt: e.startedAt,
                endedAt: e.endedAt
            ))
        case .nappy(let e):
            return .nappy(NappyImport(
                metadata: ImportEventMetadata(occurredAt: e.occurredAt, notes: e.notes.isEmpty ? nil : e.notes),
                type: e.nappyType,
                peeVolume: e.peeVolume,
                pooVolume: e.pooVolume,
                pooColor: e.pooColor
            ))
        }
    }
}
