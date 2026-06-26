import BabyTrackerDomain
import Foundation
import SwiftData

@MainActor
public final class SwiftDataEventRepository: EventRepository {
    private let store: BabyTrackerModelStore

    public init(store: BabyTrackerModelStore) {
        self.store = store
    }

    public convenience init(isStoredInMemoryOnly: Bool = false) throws {
        let store = try BabyTrackerModelStore(
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )
        self.init(store: store)
    }

    public func saveEvent(_ event: BabyEvent) throws {
        switch event {
        case let .bath(value):
            try saveBath(value)
        case let .breastFeed(value):
            try saveBreastFeed(value)
        case let .bottleFeed(value):
            try saveBottleFeed(value)
        case let .sleep(value):
            try saveSleep(value)
        case let .nappy(value):
            try saveNappy(value)
        case let .medication(value):
            try saveMedication(value)
        }

        try saveChanges()
    }

    public func loadEvent(id: UUID) throws -> BabyEvent? {
        if let storedEvent = try fetchStoredBathEvent(id: id) {
            return .bath(mapBath(storedEvent))
        }

        if let storedEvent = try fetchStoredBreastFeedEvent(id: id) {
            return .breastFeed(try mapBreastFeed(storedEvent))
        }

        if let storedEvent = try fetchStoredBottleFeedEvent(id: id) {
            return .bottleFeed(try mapBottleFeed(storedEvent))
        }

        if let storedEvent = try fetchStoredSleepEvent(id: id) {
            return .sleep(try mapSleep(storedEvent))
        }

        if let storedEvent = try fetchStoredNappyEvent(id: id) {
            return .nappy(try mapNappy(storedEvent))
        }

        if let storedEvent = try fetchStoredMedicationEvent(id: id) {
            return .medication(try mapMedication(storedEvent))
        }

        return nil
    }

    public func loadTimeline(
        for childID: UUID,
        includingDeleted: Bool = false
    ) throws -> [BabyEvent] {
        // PHASE 0 INSTRUMENTATION — measures the full-table-scan cost. `fetched`
        // counts rows materialised from the store across all six event types;
        // `surviving` counts rows that pass the childID + soft-delete filter. A
        // large fetched/surviving gap is the fetch-then-discard waste the refactor
        // removes, and the call counter exposes the repeated re-loads per refresh.
        // Behaviour below is identical to the original implementation.
        PerfLog.tick("EventRepository.loadTimeline")
        return try PerfLog.measure("EventRepository.loadTimeline") {
            // PHASE 1 — childID + soft-delete filtering now runs in SQLite via a
            // #Predicate (backed by the #Index on each Stored*Event), instead of
            // fetching every row of every table and discarding in Swift. The store
            // only materialises rows for this child, so `fetched` == `surviving`.
            let baths = try modelContext.fetch(
                FetchDescriptor<StoredBathEvent>(predicate: #Predicate { event in
                    event.childID == childID && (includingDeleted || (event.isDeleted == false && event.deletedAt == nil))
                })
            )
            let breastFeeds = try modelContext.fetch(
                FetchDescriptor<StoredBreastFeedEvent>(predicate: #Predicate { event in
                    event.childID == childID && (includingDeleted || (event.isDeleted == false && event.deletedAt == nil))
                })
            )
            let bottleFeeds = try modelContext.fetch(
                FetchDescriptor<StoredBottleFeedEvent>(predicate: #Predicate { event in
                    event.childID == childID && (includingDeleted || (event.isDeleted == false && event.deletedAt == nil))
                })
            )
            let sleeps = try modelContext.fetch(
                FetchDescriptor<StoredSleepEvent>(predicate: #Predicate { event in
                    event.childID == childID && (includingDeleted || (event.isDeleted == false && event.deletedAt == nil))
                })
            )
            let nappies = try modelContext.fetch(
                FetchDescriptor<StoredNappyEvent>(predicate: #Predicate { event in
                    event.childID == childID && (includingDeleted || (event.isDeleted == false && event.deletedAt == nil))
                })
            )
            let medications = try modelContext.fetch(
                FetchDescriptor<StoredMedicationEvent>(predicate: #Predicate { event in
                    event.childID == childID && (includingDeleted || (event.isDeleted == false && event.deletedAt == nil))
                })
            )

            var timeline: [BabyEvent] = []
            timeline.reserveCapacity(
                baths.count + breastFeeds.count + bottleFeeds.count + sleeps.count + nappies.count + medications.count
            )
            timeline.append(contentsOf: baths.map { .bath(mapBath($0)) })
            timeline.append(contentsOf: try breastFeeds.map { .breastFeed(try mapBreastFeed($0)) })
            timeline.append(contentsOf: try bottleFeeds.map { .bottleFeed(try mapBottleFeed($0)) })
            timeline.append(contentsOf: try sleeps.map { .sleep(try mapSleep($0)) })
            timeline.append(contentsOf: try nappies.map { .nappy(try mapNappy($0)) })
            timeline.append(contentsOf: try medications.map { .medication(try mapMedication($0)) })

            PerfLog.event("EventRepository.loadTimeline fetched=\(timeline.count) surviving=\(timeline.count)")

            return timeline.sorted { left, right in
                left.metadata.occurredAt > right.metadata.occurredAt
            }
        }
    }

    public func loadEvents(
        for childID: UUID,
        on day: Date,
        calendar: Calendar = .current,
        includingDeleted: Bool = false
    ) throws -> [BabyEvent] {
        // PHASE 0 INSTRUMENTATION — each call re-runs the full `loadTimeline`
        // above and then discards everything outside `day`; the call counter shows
        // how many times this happens per refresh (one per visible timeline day).
        PerfLog.tick("EventRepository.loadEvents(on:)")
        return try PerfLog.measure("EventRepository.loadEvents(on:)") {
            let startOfDay = calendar.startOfDay(for: day)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                return []
            }

            return try loadTimeline(for: childID, includingDeleted: includingDeleted)
                .filter { event in
                    eventOverlapsDay(event, startOfDay: startOfDay, endOfDay: endOfDay)
                }
        }
    }

    private func eventOverlapsDay(
        _ event: BabyEvent,
        startOfDay: Date,
        endOfDay: Date
    ) -> Bool {
        switch event {
        case let .sleep(sleep):
            // Active sleep (nil endedAt) is treated as still ongoing
            let end = sleep.endedAt ?? Date.distantFuture
            return sleep.startedAt < endOfDay && end > startOfDay
        case let .breastFeed(feed):
            return feed.startedAt < endOfDay && feed.endedAt > startOfDay
        case let .bath(bath):
            return bath.metadata.occurredAt >= startOfDay && bath.metadata.occurredAt < endOfDay
        case let .bottleFeed(feed):
            return feed.metadata.occurredAt >= startOfDay && feed.metadata.occurredAt < endOfDay
        case let .nappy(nappy):
            return nappy.metadata.occurredAt >= startOfDay && nappy.metadata.occurredAt < endOfDay
        case let .medication(medication):
            return medication.metadata.occurredAt >= startOfDay && medication.metadata.occurredAt < endOfDay
        }
    }

    public func loadActiveSleepEvent(for childID: UUID) throws -> SleepEvent? {
        // PHASE 0 INSTRUMENTATION — another full StoredSleepEvent table scan per refresh.
        PerfLog.tick("EventRepository.loadActiveSleepEvent")
        return try PerfLog.measure("EventRepository.loadActiveSleepEvent") {
            // PHASE 1 — filter in SQLite (childID, not soft-deleted, still running).
            try modelContext.fetch(
                FetchDescriptor<StoredSleepEvent>(predicate: #Predicate { event in
                    event.childID == childID && event.isDeleted == false && event.deletedAt == nil && event.endedAt == nil
                })
            )
            .map(mapSleep)
            .sorted { left, right in left.startedAt > right.startedAt }
            .first
        }
    }

    public func softDeleteEvent(
        id: UUID,
        deletedAt: Date,
        deletedBy: UUID
    ) throws {
        if let storedEvent = try fetchStoredBathEvent(id: id) {
            markDeleted(storedEvent, deletedAt: deletedAt, deletedBy: deletedBy)
        } else if let storedEvent = try fetchStoredBreastFeedEvent(id: id) {
            markDeleted(storedEvent, deletedAt: deletedAt, deletedBy: deletedBy)
        } else if let storedEvent = try fetchStoredBottleFeedEvent(id: id) {
            markDeleted(storedEvent, deletedAt: deletedAt, deletedBy: deletedBy)
        } else if let storedEvent = try fetchStoredSleepEvent(id: id) {
            markDeleted(storedEvent, deletedAt: deletedAt, deletedBy: deletedBy)
        } else if let storedEvent = try fetchStoredNappyEvent(id: id) {
            markDeleted(storedEvent, deletedAt: deletedAt, deletedBy: deletedBy)
        } else if let storedEvent = try fetchStoredMedicationEvent(id: id) {
            markDeleted(storedEvent, deletedAt: deletedAt, deletedBy: deletedBy)
        }

        try saveChanges()
    }

    private var modelContext: ModelContext {
        store.modelContainer.mainContext
    }

    private func saveBath(_ event: BathEvent) throws {
        let existingEvent = try fetchStoredBathEvent(id: event.id)
        let storedEvent = existingEvent ?? StoredBathEvent(
            id: event.id,
            childID: event.metadata.childID,
            occurredAt: event.metadata.occurredAt,
            createdAt: event.metadata.createdAt,
            createdBy: event.metadata.createdBy,
            updatedAt: event.metadata.updatedAt,
            updatedBy: event.metadata.updatedBy,
            notes: event.metadata.notes,
            isDeleted: event.metadata.isDeleted,
            deletedAt: event.metadata.deletedAt,
            usedShampoo: event.usedShampoo,
            usedSoap: event.usedSoap,
            syncStateRawValue: SyncState.pendingSync.rawValue,
            lastSyncedAt: nil,
            lastSyncErrorCode: nil
        )

        applyMetadata(event.metadata, to: storedEvent)
        storedEvent.usedShampoo = event.usedShampoo
        storedEvent.usedSoap = event.usedSoap
        markPending(storedEvent)

        if existingEvent == nil {
            modelContext.insert(storedEvent)
        }
    }

    private func saveMedication(_ event: MedicationEvent) throws {
        let existingEvent = try fetchStoredMedicationEvent(id: event.id)
        let storedEvent = existingEvent ?? StoredMedicationEvent(
            id: event.id,
            childID: event.metadata.childID,
            occurredAt: event.metadata.occurredAt,
            createdAt: event.metadata.createdAt,
            createdBy: event.metadata.createdBy,
            updatedAt: event.metadata.updatedAt,
            updatedBy: event.metadata.updatedBy,
            notes: event.metadata.notes,
            isDeleted: event.metadata.isDeleted,
            deletedAt: event.metadata.deletedAt,
            medicineName: event.medicineName,
            amount: event.amount,
            unitRawValue: event.unit.rawValue,
            customUnitLabel: event.customUnitLabel,
            syncStateRawValue: SyncState.pendingSync.rawValue,
            lastSyncedAt: nil,
            lastSyncErrorCode: nil
        )

        applyMetadata(event.metadata, to: storedEvent)
        storedEvent.medicineName = event.medicineName
        storedEvent.amount = event.amount
        storedEvent.unitRawValue = event.unit.rawValue
        storedEvent.customUnitLabel = event.customUnitLabel
        markPending(storedEvent)

        if existingEvent == nil {
            modelContext.insert(storedEvent)
        }
    }

    private func saveBreastFeed(_ event: BreastFeedEvent) throws {
        let existingEvent = try fetchStoredBreastFeedEvent(id: event.id)
        let storedEvent = existingEvent ?? StoredBreastFeedEvent(
            id: event.id,
            childID: event.metadata.childID,
            occurredAt: event.metadata.occurredAt,
            createdAt: event.metadata.createdAt,
            createdBy: event.metadata.createdBy,
            updatedAt: event.metadata.updatedAt,
            updatedBy: event.metadata.updatedBy,
            notes: event.metadata.notes,
            isDeleted: event.metadata.isDeleted,
            deletedAt: event.metadata.deletedAt,
            sideRawValue: event.side?.rawValue ?? "",
            startedAt: event.startedAt,
            endedAt: event.endedAt,
            leftDurationSeconds: event.leftDurationSeconds,
            rightDurationSeconds: event.rightDurationSeconds,
            syncStateRawValue: SyncState.pendingSync.rawValue,
            lastSyncedAt: nil,
            lastSyncErrorCode: nil
        )

        applyMetadata(event.metadata, to: storedEvent)
        storedEvent.sideRawValue = event.side?.rawValue ?? ""
        storedEvent.startedAt = event.startedAt
        storedEvent.endedAt = event.endedAt
        storedEvent.leftDurationSeconds = event.leftDurationSeconds
        storedEvent.rightDurationSeconds = event.rightDurationSeconds
        markPending(storedEvent)

        if existingEvent == nil {
            modelContext.insert(storedEvent)
        }
    }

    private func saveBottleFeed(_ event: BottleFeedEvent) throws {
        let existingEvent = try fetchStoredBottleFeedEvent(id: event.id)
        let storedEvent = existingEvent ?? StoredBottleFeedEvent(
            id: event.id,
            childID: event.metadata.childID,
            occurredAt: event.metadata.occurredAt,
            createdAt: event.metadata.createdAt,
            createdBy: event.metadata.createdBy,
            updatedAt: event.metadata.updatedAt,
            updatedBy: event.metadata.updatedBy,
            notes: event.metadata.notes,
            isDeleted: event.metadata.isDeleted,
            deletedAt: event.metadata.deletedAt,
            amountMilliliters: event.amountMilliliters,
            milkTypeRawValue: event.milkType?.rawValue,
            syncStateRawValue: SyncState.pendingSync.rawValue,
            lastSyncedAt: nil,
            lastSyncErrorCode: nil
        )

        applyMetadata(event.metadata, to: storedEvent)
        storedEvent.amountMilliliters = event.amountMilliliters
        storedEvent.milkTypeRawValue = event.milkType?.rawValue
        markPending(storedEvent)

        if existingEvent == nil {
            modelContext.insert(storedEvent)
        }
    }

    private func saveSleep(_ event: SleepEvent) throws {
        let existingEvent = try fetchStoredSleepEvent(id: event.id)
        let storedEvent = existingEvent ?? StoredSleepEvent(
            id: event.id,
            childID: event.metadata.childID,
            occurredAt: event.metadata.occurredAt,
            createdAt: event.metadata.createdAt,
            createdBy: event.metadata.createdBy,
            updatedAt: event.metadata.updatedAt,
            updatedBy: event.metadata.updatedBy,
            notes: event.metadata.notes,
            isDeleted: event.metadata.isDeleted,
            deletedAt: event.metadata.deletedAt,
            startedAt: event.startedAt,
            endedAt: event.endedAt,
            syncStateRawValue: SyncState.pendingSync.rawValue,
            lastSyncedAt: nil,
            lastSyncErrorCode: nil
        )

        applyMetadata(event.metadata, to: storedEvent)
        storedEvent.startedAt = event.startedAt
        storedEvent.endedAt = event.endedAt
        markPending(storedEvent)

        if existingEvent == nil {
            modelContext.insert(storedEvent)
        }
    }

    private func saveNappy(_ event: NappyEvent) throws {
        let existingEvent = try fetchStoredNappyEvent(id: event.id)
        let storedEvent = existingEvent ?? StoredNappyEvent(
            id: event.id,
            childID: event.metadata.childID,
            occurredAt: event.metadata.occurredAt,
            createdAt: event.metadata.createdAt,
            createdBy: event.metadata.createdBy,
            updatedAt: event.metadata.updatedAt,
            updatedBy: event.metadata.updatedBy,
            notes: event.metadata.notes,
            isDeleted: event.metadata.isDeleted,
            deletedAt: event.metadata.deletedAt,
            typeRawValue: event.type.rawValue,
            intensityRawValue: nil,
            peeVolumeRawValue: event.peeVolume?.rawValue,
            pooVolumeRawValue: event.pooVolume?.rawValue,
            pooColorRawValue: event.pooColor?.rawValue,
            syncStateRawValue: SyncState.pendingSync.rawValue,
            lastSyncedAt: nil,
            lastSyncErrorCode: nil
        )

        applyMetadata(event.metadata, to: storedEvent)
        storedEvent.typeRawValue = event.type.rawValue
        storedEvent.peeVolumeRawValue = event.peeVolume?.rawValue
        storedEvent.pooVolumeRawValue = event.pooVolume?.rawValue
        storedEvent.pooColorRawValue = event.pooColor?.rawValue
        markPending(storedEvent)

        if existingEvent == nil {
            modelContext.insert(storedEvent)
        }
    }

    // PHASE 1 — fetch a single record by id with a #Predicate + fetchLimit so the
    // store stops materialising the whole table just to find one row by id.
    private func fetchStoredBathEvent(id: UUID) throws -> StoredBathEvent? {
        var descriptor = FetchDescriptor<StoredBathEvent>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchStoredBreastFeedEvent(id: UUID) throws -> StoredBreastFeedEvent? {
        var descriptor = FetchDescriptor<StoredBreastFeedEvent>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchStoredBottleFeedEvent(id: UUID) throws -> StoredBottleFeedEvent? {
        var descriptor = FetchDescriptor<StoredBottleFeedEvent>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchStoredSleepEvent(id: UUID) throws -> StoredSleepEvent? {
        var descriptor = FetchDescriptor<StoredSleepEvent>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchStoredNappyEvent(id: UUID) throws -> StoredNappyEvent? {
        var descriptor = FetchDescriptor<StoredNappyEvent>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchStoredMedicationEvent(id: UUID) throws -> StoredMedicationEvent? {
        var descriptor = FetchDescriptor<StoredMedicationEvent>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func mapBath(_ storedEvent: StoredBathEvent) -> BathEvent {
        BathEvent(
            metadata: makeMetadata(
                id: storedEvent.id,
                childID: storedEvent.childID,
                occurredAt: storedEvent.occurredAt,
                createdAt: storedEvent.createdAt,
                createdBy: storedEvent.createdBy,
                updatedAt: storedEvent.updatedAt,
                updatedBy: storedEvent.updatedBy,
                notes: storedEvent.notes,
                isDeleted: storedEvent.isDeleted,
                deletedAt: storedEvent.deletedAt
            ),
            usedShampoo: storedEvent.usedShampoo,
            usedSoap: storedEvent.usedSoap
        )
    }

    private func mapMedication(_ storedEvent: StoredMedicationEvent) throws -> MedicationEvent {
        let unit = MedicationUnit(rawValue: storedEvent.unitRawValue) ?? .custom

        return try MedicationEvent(
            metadata: makeMetadata(
                id: storedEvent.id,
                childID: storedEvent.childID,
                occurredAt: storedEvent.occurredAt,
                createdAt: storedEvent.createdAt,
                createdBy: storedEvent.createdBy,
                updatedAt: storedEvent.updatedAt,
                updatedBy: storedEvent.updatedBy,
                notes: storedEvent.notes,
                isDeleted: storedEvent.isDeleted,
                deletedAt: storedEvent.deletedAt
            ),
            medicineName: storedEvent.medicineName,
            amount: storedEvent.amount,
            unit: unit,
            customUnitLabel: storedEvent.customUnitLabel
        )
    }

    private func mapBreastFeed(_ storedEvent: StoredBreastFeedEvent) throws -> BreastFeedEvent {
        let side: BreastSide?

        if storedEvent.sideRawValue.isEmpty {
            side = nil
        } else if let storedSide = BreastSide(rawValue: storedEvent.sideRawValue) {
            side = storedSide
        } else {
            throw BabyEventError.invalidDateRange
        }

        return try BreastFeedEvent(
            metadata: makeMetadata(
                id: storedEvent.id,
                childID: storedEvent.childID,
                occurredAt: storedEvent.occurredAt,
                createdAt: storedEvent.createdAt,
                createdBy: storedEvent.createdBy,
                updatedAt: storedEvent.updatedAt,
                updatedBy: storedEvent.updatedBy,
                notes: storedEvent.notes,
                isDeleted: storedEvent.isDeleted,
                deletedAt: storedEvent.deletedAt
            ),
            side: side,
            startedAt: storedEvent.startedAt,
            endedAt: storedEvent.endedAt,
            leftDurationSeconds: storedEvent.leftDurationSeconds,
            rightDurationSeconds: storedEvent.rightDurationSeconds
        )
    }

    private func mapBottleFeed(_ storedEvent: StoredBottleFeedEvent) throws -> BottleFeedEvent {
        let milkType = storedEvent.milkTypeRawValue.flatMap(MilkType.init(rawValue:))

        return try BottleFeedEvent(
            metadata: makeMetadata(
                id: storedEvent.id,
                childID: storedEvent.childID,
                occurredAt: storedEvent.occurredAt,
                createdAt: storedEvent.createdAt,
                createdBy: storedEvent.createdBy,
                updatedAt: storedEvent.updatedAt,
                updatedBy: storedEvent.updatedBy,
                notes: storedEvent.notes,
                isDeleted: storedEvent.isDeleted,
                deletedAt: storedEvent.deletedAt
            ),
            amountMilliliters: storedEvent.amountMilliliters,
            milkType: milkType
        )
    }

    private func mapSleep(_ storedEvent: StoredSleepEvent) throws -> SleepEvent {
        try SleepEvent(
            metadata: makeMetadata(
                id: storedEvent.id,
                childID: storedEvent.childID,
                occurredAt: storedEvent.occurredAt,
                createdAt: storedEvent.createdAt,
                createdBy: storedEvent.createdBy,
                updatedAt: storedEvent.updatedAt,
                updatedBy: storedEvent.updatedBy,
                notes: storedEvent.notes,
                isDeleted: storedEvent.isDeleted,
                deletedAt: storedEvent.deletedAt
            ),
            startedAt: storedEvent.startedAt,
            endedAt: storedEvent.endedAt
        )
    }

    private func mapNappy(_ storedEvent: StoredNappyEvent) throws -> NappyEvent {
        guard let type = NappyType(rawValue: storedEvent.typeRawValue) else {
            throw NappyEntryError.pooColorRequiresPooOrMixed
        }

        return try NappyEvent(
            metadata: makeMetadata(
                id: storedEvent.id,
                childID: storedEvent.childID,
                occurredAt: storedEvent.occurredAt,
                createdAt: storedEvent.createdAt,
                createdBy: storedEvent.createdBy,
                updatedAt: storedEvent.updatedAt,
                updatedBy: storedEvent.updatedBy,
                notes: storedEvent.notes,
                isDeleted: storedEvent.isDeleted,
                deletedAt: storedEvent.deletedAt
            ),
            type: type,
            peeVolume: storedEvent.peeVolumeRawValue.flatMap(NappyVolume.init(rawValue:)),
            pooVolume: storedEvent.pooVolumeRawValue.flatMap(NappyVolume.init(rawValue:)),
            pooColor: storedEvent.pooColorRawValue.flatMap(PooColor.init(rawValue:))
        )
    }

    private func makeMetadata(
        id: UUID,
        childID: UUID,
        occurredAt: Date,
        createdAt: Date,
        createdBy: UUID,
        updatedAt: Date,
        updatedBy: UUID,
        notes: String,
        isDeleted: Bool,
        deletedAt: Date?
    ) -> EventMetadata {
        EventMetadata(
            id: id,
            childID: childID,
            occurredAt: occurredAt,
            createdAt: createdAt,
            createdBy: createdBy,
            updatedAt: updatedAt,
            updatedBy: updatedBy,
            notes: notes,
            isDeleted: isSoftDeleted(isDeleted: isDeleted, deletedAt: deletedAt),
            deletedAt: deletedAt
        )
    }

    private func isSoftDeleted(
        isDeleted: Bool,
        deletedAt: Date?
    ) -> Bool {
        isDeleted || deletedAt != nil
    }

    private func applyMetadata(_ metadata: EventMetadata, to storedEvent: StoredBathEvent) {
        storedEvent.childID = metadata.childID
        storedEvent.occurredAt = metadata.occurredAt
        storedEvent.createdAt = metadata.createdAt
        storedEvent.createdBy = metadata.createdBy
        storedEvent.updatedAt = metadata.updatedAt
        storedEvent.updatedBy = metadata.updatedBy
        storedEvent.notes = metadata.notes
        storedEvent.isDeleted = metadata.isDeleted
        storedEvent.deletedAt = metadata.deletedAt
    }

    private func applyMetadata(_ metadata: EventMetadata, to storedEvent: StoredMedicationEvent) {
        storedEvent.childID = metadata.childID
        storedEvent.occurredAt = metadata.occurredAt
        storedEvent.createdAt = metadata.createdAt
        storedEvent.createdBy = metadata.createdBy
        storedEvent.updatedAt = metadata.updatedAt
        storedEvent.updatedBy = metadata.updatedBy
        storedEvent.notes = metadata.notes
        storedEvent.isDeleted = metadata.isDeleted
        storedEvent.deletedAt = metadata.deletedAt
    }

    private func applyMetadata(_ metadata: EventMetadata, to storedEvent: StoredBreastFeedEvent) {
        storedEvent.childID = metadata.childID
        storedEvent.occurredAt = metadata.occurredAt
        storedEvent.createdAt = metadata.createdAt
        storedEvent.createdBy = metadata.createdBy
        storedEvent.updatedAt = metadata.updatedAt
        storedEvent.updatedBy = metadata.updatedBy
        storedEvent.notes = metadata.notes
        storedEvent.isDeleted = metadata.isDeleted
        storedEvent.deletedAt = metadata.deletedAt
    }

    private func applyMetadata(_ metadata: EventMetadata, to storedEvent: StoredBottleFeedEvent) {
        storedEvent.childID = metadata.childID
        storedEvent.occurredAt = metadata.occurredAt
        storedEvent.createdAt = metadata.createdAt
        storedEvent.createdBy = metadata.createdBy
        storedEvent.updatedAt = metadata.updatedAt
        storedEvent.updatedBy = metadata.updatedBy
        storedEvent.notes = metadata.notes
        storedEvent.isDeleted = metadata.isDeleted
        storedEvent.deletedAt = metadata.deletedAt
    }

    private func applyMetadata(_ metadata: EventMetadata, to storedEvent: StoredSleepEvent) {
        storedEvent.childID = metadata.childID
        storedEvent.occurredAt = metadata.occurredAt
        storedEvent.createdAt = metadata.createdAt
        storedEvent.createdBy = metadata.createdBy
        storedEvent.updatedAt = metadata.updatedAt
        storedEvent.updatedBy = metadata.updatedBy
        storedEvent.notes = metadata.notes
        storedEvent.isDeleted = metadata.isDeleted
        storedEvent.deletedAt = metadata.deletedAt
    }

    private func applyMetadata(_ metadata: EventMetadata, to storedEvent: StoredNappyEvent) {
        storedEvent.childID = metadata.childID
        storedEvent.occurredAt = metadata.occurredAt
        storedEvent.createdAt = metadata.createdAt
        storedEvent.createdBy = metadata.createdBy
        storedEvent.updatedAt = metadata.updatedAt
        storedEvent.updatedBy = metadata.updatedBy
        storedEvent.notes = metadata.notes
        storedEvent.isDeleted = metadata.isDeleted
        storedEvent.deletedAt = metadata.deletedAt
    }

    private func markDeleted(
        _ storedEvent: StoredBathEvent,
        deletedAt: Date,
        deletedBy: UUID
    ) {
        storedEvent.isDeleted = true
        storedEvent.deletedAt = deletedAt
        storedEvent.updatedAt = deletedAt
        storedEvent.updatedBy = deletedBy
        markPending(storedEvent)
    }

    private func markDeleted(
        _ storedEvent: StoredMedicationEvent,
        deletedAt: Date,
        deletedBy: UUID
    ) {
        storedEvent.isDeleted = true
        storedEvent.deletedAt = deletedAt
        storedEvent.updatedAt = deletedAt
        storedEvent.updatedBy = deletedBy
        markPending(storedEvent)
    }

    private func markDeleted(
        _ storedEvent: StoredBreastFeedEvent,
        deletedAt: Date,
        deletedBy: UUID
    ) {
        storedEvent.isDeleted = true
        storedEvent.deletedAt = deletedAt
        storedEvent.updatedAt = deletedAt
        storedEvent.updatedBy = deletedBy
        markPending(storedEvent)
    }

    private func markDeleted(
        _ storedEvent: StoredBottleFeedEvent,
        deletedAt: Date,
        deletedBy: UUID
    ) {
        storedEvent.isDeleted = true
        storedEvent.deletedAt = deletedAt
        storedEvent.updatedAt = deletedAt
        storedEvent.updatedBy = deletedBy
        markPending(storedEvent)
    }

    private func markDeleted(
        _ storedEvent: StoredSleepEvent,
        deletedAt: Date,
        deletedBy: UUID
    ) {
        storedEvent.isDeleted = true
        storedEvent.deletedAt = deletedAt
        storedEvent.updatedAt = deletedAt
        storedEvent.updatedBy = deletedBy
        markPending(storedEvent)
    }

    private func markDeleted(
        _ storedEvent: StoredNappyEvent,
        deletedAt: Date,
        deletedBy: UUID
    ) {
        storedEvent.isDeleted = true
        storedEvent.deletedAt = deletedAt
        storedEvent.updatedAt = deletedAt
        storedEvent.updatedBy = deletedBy
        markPending(storedEvent)
    }

    private func markPending(_ storedEvent: StoredBathEvent) {
        storedEvent.syncStateRawValue = SyncState.pendingSync.rawValue
        storedEvent.lastSyncErrorCode = nil
    }

    private func markPending(_ storedEvent: StoredMedicationEvent) {
        storedEvent.syncStateRawValue = SyncState.pendingSync.rawValue
        storedEvent.lastSyncErrorCode = nil
    }

    private func markPending(_ storedEvent: StoredBreastFeedEvent) {
        storedEvent.syncStateRawValue = SyncState.pendingSync.rawValue
        storedEvent.lastSyncErrorCode = nil
    }

    private func markPending(_ storedEvent: StoredBottleFeedEvent) {
        storedEvent.syncStateRawValue = SyncState.pendingSync.rawValue
        storedEvent.lastSyncErrorCode = nil
    }

    private func markPending(_ storedEvent: StoredSleepEvent) {
        storedEvent.syncStateRawValue = SyncState.pendingSync.rawValue
        storedEvent.lastSyncErrorCode = nil
    }

    private func markPending(_ storedEvent: StoredNappyEvent) {
        storedEvent.syncStateRawValue = SyncState.pendingSync.rawValue
        storedEvent.lastSyncErrorCode = nil
    }

    private func saveChanges() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
}
