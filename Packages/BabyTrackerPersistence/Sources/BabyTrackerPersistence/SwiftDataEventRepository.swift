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
        var timeline: [BabyEvent] = []

        timeline.append(contentsOf: try fetchBathEvents(childID: childID, includingDeleted: includingDeleted)
            .map { .bath(mapBath($0)) })
        timeline.append(contentsOf: try fetchBreastFeedEvents(childID: childID, includingDeleted: includingDeleted)
            .map { .breastFeed(try mapBreastFeed($0)) })
        timeline.append(contentsOf: try fetchBottleFeedEvents(childID: childID, includingDeleted: includingDeleted)
            .map { .bottleFeed(try mapBottleFeed($0)) })
        timeline.append(contentsOf: try fetchSleepEvents(childID: childID, includingDeleted: includingDeleted)
            .map { .sleep(try mapSleep($0)) })
        timeline.append(contentsOf: try fetchNappyEvents(childID: childID, includingDeleted: includingDeleted)
            .map { .nappy(try mapNappy($0)) })
        timeline.append(contentsOf: try fetchMedicationEvents(childID: childID, includingDeleted: includingDeleted)
            .map { .medication(try mapMedication($0)) })

        return timeline.sorted { left, right in
            left.metadata.occurredAt > right.metadata.occurredAt
        }
    }

    public func loadEvents(
        for childID: UUID,
        on day: Date,
        calendar: Calendar = .current,
        includingDeleted: Bool = false
    ) throws -> [BabyEvent] {
        let startOfDay = calendar.startOfDay(for: day)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        var dayEvents: [BabyEvent] = []

        dayEvents.append(contentsOf: try fetchBathEvents(
            childID: childID,
            occurringFrom: startOfDay,
            to: endOfDay,
            includingDeleted: includingDeleted
        ).map { .bath(mapBath($0)) })
        dayEvents.append(contentsOf: try fetchBreastFeedEvents(
            childID: childID,
            overlapping: startOfDay,
            to: endOfDay,
            includingDeleted: includingDeleted
        ).map { .breastFeed(try mapBreastFeed($0)) })
        dayEvents.append(contentsOf: try fetchBottleFeedEvents(
            childID: childID,
            occurringFrom: startOfDay,
            to: endOfDay,
            includingDeleted: includingDeleted
        ).map { .bottleFeed(try mapBottleFeed($0)) })
        dayEvents.append(contentsOf: try fetchSleepEvents(
            childID: childID,
            overlapping: startOfDay,
            to: endOfDay,
            includingDeleted: includingDeleted
        ).map { .sleep(try mapSleep($0)) })
        dayEvents.append(contentsOf: try fetchNappyEvents(
            childID: childID,
            occurringFrom: startOfDay,
            to: endOfDay,
            includingDeleted: includingDeleted
        ).map { .nappy(try mapNappy($0)) })
        dayEvents.append(contentsOf: try fetchMedicationEvents(
            childID: childID,
            occurringFrom: startOfDay,
            to: endOfDay,
            includingDeleted: includingDeleted
        ).map { .medication(try mapMedication($0)) })

        return dayEvents.sorted { left, right in
            left.metadata.occurredAt > right.metadata.occurredAt
        }
    }

    public func loadActiveSleepEvent(for childID: UUID) throws -> SleepEvent? {
        let predicate = #Predicate<StoredSleepEvent> { storedEvent in
            storedEvent.childID == childID &&
            storedEvent.endedAt == nil &&
            !storedEvent.isDeleted &&
            storedEvent.deletedAt == nil
        }
        var descriptor = FetchDescriptor<StoredSleepEvent>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.startedAt, order: .reverse)]

        guard let storedEvent = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return try mapSleep(storedEvent)
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

    // MARK: - Timeline fetches (childID-scoped, unbounded by date)

    private func fetchBathEvents(childID: UUID, includingDeleted: Bool) throws -> [StoredBathEvent] {
        let predicate: Predicate<StoredBathEvent>
        if includingDeleted {
            predicate = #Predicate<StoredBathEvent> { $0.childID == childID }
        } else {
            predicate = #Predicate<StoredBathEvent> { storedEvent in
                storedEvent.childID == childID &&
                !storedEvent.isDeleted &&
                storedEvent.deletedAt == nil
            }
        }
        return try modelContext.fetch(FetchDescriptor<StoredBathEvent>(predicate: predicate))
    }

    private func fetchBreastFeedEvents(childID: UUID, includingDeleted: Bool) throws -> [StoredBreastFeedEvent] {
        let predicate: Predicate<StoredBreastFeedEvent>
        if includingDeleted {
            predicate = #Predicate<StoredBreastFeedEvent> { $0.childID == childID }
        } else {
            predicate = #Predicate<StoredBreastFeedEvent> { storedEvent in
                storedEvent.childID == childID &&
                !storedEvent.isDeleted &&
                storedEvent.deletedAt == nil
            }
        }
        return try modelContext.fetch(FetchDescriptor<StoredBreastFeedEvent>(predicate: predicate))
    }

    private func fetchBottleFeedEvents(childID: UUID, includingDeleted: Bool) throws -> [StoredBottleFeedEvent] {
        let predicate: Predicate<StoredBottleFeedEvent>
        if includingDeleted {
            predicate = #Predicate<StoredBottleFeedEvent> { $0.childID == childID }
        } else {
            predicate = #Predicate<StoredBottleFeedEvent> { storedEvent in
                storedEvent.childID == childID &&
                !storedEvent.isDeleted &&
                storedEvent.deletedAt == nil
            }
        }
        return try modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>(predicate: predicate))
    }

    private func fetchSleepEvents(childID: UUID, includingDeleted: Bool) throws -> [StoredSleepEvent] {
        let predicate: Predicate<StoredSleepEvent>
        if includingDeleted {
            predicate = #Predicate<StoredSleepEvent> { $0.childID == childID }
        } else {
            predicate = #Predicate<StoredSleepEvent> { storedEvent in
                storedEvent.childID == childID &&
                !storedEvent.isDeleted &&
                storedEvent.deletedAt == nil
            }
        }
        return try modelContext.fetch(FetchDescriptor<StoredSleepEvent>(predicate: predicate))
    }

    private func fetchNappyEvents(childID: UUID, includingDeleted: Bool) throws -> [StoredNappyEvent] {
        let predicate: Predicate<StoredNappyEvent>
        if includingDeleted {
            predicate = #Predicate<StoredNappyEvent> { $0.childID == childID }
        } else {
            predicate = #Predicate<StoredNappyEvent> { storedEvent in
                storedEvent.childID == childID &&
                !storedEvent.isDeleted &&
                storedEvent.deletedAt == nil
            }
        }
        return try modelContext.fetch(FetchDescriptor<StoredNappyEvent>(predicate: predicate))
    }

    private func fetchMedicationEvents(childID: UUID, includingDeleted: Bool) throws -> [StoredMedicationEvent] {
        let predicate: Predicate<StoredMedicationEvent>
        if includingDeleted {
            predicate = #Predicate<StoredMedicationEvent> { $0.childID == childID }
        } else {
            predicate = #Predicate<StoredMedicationEvent> { storedEvent in
                storedEvent.childID == childID &&
                !storedEvent.isDeleted &&
                storedEvent.deletedAt == nil
            }
        }
        return try modelContext.fetch(FetchDescriptor<StoredMedicationEvent>(predicate: predicate))
    }

    // MARK: - Day-range fetches (childID + date-window scoped)
    //
    // Instant events (bath/bottle feed/nappy/medication) are filtered on
    // `occurredAt` falling within [startOfDay, endOfDay). Sleep and breast
    // feed events have a duration and must use overlap semantics instead of a
    // single-instant comparison, since a session can span the day boundary.

    private func fetchBathEvents(
        childID: UUID,
        occurringFrom startOfDay: Date,
        to endOfDay: Date,
        includingDeleted: Bool
    ) throws -> [StoredBathEvent] {
        let predicate: Predicate<StoredBathEvent>
        if includingDeleted {
            predicate = #Predicate<StoredBathEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.occurredAt >= startOfDay &&
                storedEvent.occurredAt < endOfDay
            }
        } else {
            predicate = #Predicate<StoredBathEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.occurredAt >= startOfDay &&
                storedEvent.occurredAt < endOfDay &&
                !storedEvent.isDeleted &&
                storedEvent.deletedAt == nil
            }
        }
        return try modelContext.fetch(FetchDescriptor<StoredBathEvent>(predicate: predicate))
    }

    private func fetchBottleFeedEvents(
        childID: UUID,
        occurringFrom startOfDay: Date,
        to endOfDay: Date,
        includingDeleted: Bool
    ) throws -> [StoredBottleFeedEvent] {
        let predicate: Predicate<StoredBottleFeedEvent>
        if includingDeleted {
            predicate = #Predicate<StoredBottleFeedEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.occurredAt >= startOfDay &&
                storedEvent.occurredAt < endOfDay
            }
        } else {
            predicate = #Predicate<StoredBottleFeedEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.occurredAt >= startOfDay &&
                storedEvent.occurredAt < endOfDay &&
                !storedEvent.isDeleted &&
                storedEvent.deletedAt == nil
            }
        }
        return try modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>(predicate: predicate))
    }

    private func fetchNappyEvents(
        childID: UUID,
        occurringFrom startOfDay: Date,
        to endOfDay: Date,
        includingDeleted: Bool
    ) throws -> [StoredNappyEvent] {
        let predicate: Predicate<StoredNappyEvent>
        if includingDeleted {
            predicate = #Predicate<StoredNappyEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.occurredAt >= startOfDay &&
                storedEvent.occurredAt < endOfDay
            }
        } else {
            predicate = #Predicate<StoredNappyEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.occurredAt >= startOfDay &&
                storedEvent.occurredAt < endOfDay &&
                !storedEvent.isDeleted &&
                storedEvent.deletedAt == nil
            }
        }
        return try modelContext.fetch(FetchDescriptor<StoredNappyEvent>(predicate: predicate))
    }

    private func fetchMedicationEvents(
        childID: UUID,
        occurringFrom startOfDay: Date,
        to endOfDay: Date,
        includingDeleted: Bool
    ) throws -> [StoredMedicationEvent] {
        let predicate: Predicate<StoredMedicationEvent>
        if includingDeleted {
            predicate = #Predicate<StoredMedicationEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.occurredAt >= startOfDay &&
                storedEvent.occurredAt < endOfDay
            }
        } else {
            predicate = #Predicate<StoredMedicationEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.occurredAt >= startOfDay &&
                storedEvent.occurredAt < endOfDay &&
                !storedEvent.isDeleted &&
                storedEvent.deletedAt == nil
            }
        }
        return try modelContext.fetch(FetchDescriptor<StoredMedicationEvent>(predicate: predicate))
    }

    private func fetchBreastFeedEvents(
        childID: UUID,
        overlapping startOfDay: Date,
        to endOfDay: Date,
        includingDeleted: Bool
    ) throws -> [StoredBreastFeedEvent] {
        // endedAt is non-optional for breast feeds (a feed is only ever saved
        // once it has an end time), so a plain overlap comparison is safe.
        let predicate: Predicate<StoredBreastFeedEvent>
        if includingDeleted {
            predicate = #Predicate<StoredBreastFeedEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.startedAt < endOfDay &&
                storedEvent.endedAt > startOfDay
            }
        } else {
            predicate = #Predicate<StoredBreastFeedEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.startedAt < endOfDay &&
                storedEvent.endedAt > startOfDay &&
                !storedEvent.isDeleted &&
                storedEvent.deletedAt == nil
            }
        }
        return try modelContext.fetch(FetchDescriptor<StoredBreastFeedEvent>(predicate: predicate))
    }

    private func fetchSleepEvents(
        childID: UUID,
        overlapping startOfDay: Date,
        to endOfDay: Date,
        includingDeleted: Bool
    ) throws -> [StoredSleepEvent] {
        // Sleep's `endedAt` is optional (nil while a session is ongoing), and
        // SwiftData's #Predicate macro does not reliably support comparing an
        // Optional<Date> against a Date. Splitting into two predicates avoids
        // that: one for still-active sessions (endedAt == nil, a nil-check is
        // well supported) and one for completed sessions, which relies on the
        // app-wide invariant (enforced by SleepEvent.updating/LogSleepUseCase)
        // that `occurredAt == endedAt` once a session has ended, letting us
        // compare the non-optional `occurredAt` instead of `endedAt`.
        let activePredicate: Predicate<StoredSleepEvent>
        let endedPredicate: Predicate<StoredSleepEvent>

        if includingDeleted {
            activePredicate = #Predicate<StoredSleepEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.endedAt == nil &&
                storedEvent.startedAt < endOfDay
            }
            endedPredicate = #Predicate<StoredSleepEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.endedAt != nil &&
                storedEvent.startedAt < endOfDay &&
                storedEvent.occurredAt > startOfDay
            }
        } else {
            activePredicate = #Predicate<StoredSleepEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.endedAt == nil &&
                storedEvent.startedAt < endOfDay &&
                !storedEvent.isDeleted &&
                storedEvent.deletedAt == nil
            }
            endedPredicate = #Predicate<StoredSleepEvent> { storedEvent in
                storedEvent.childID == childID &&
                storedEvent.endedAt != nil &&
                storedEvent.startedAt < endOfDay &&
                storedEvent.occurredAt > startOfDay &&
                !storedEvent.isDeleted &&
                storedEvent.deletedAt == nil
            }
        }

        let activeEvents = try modelContext.fetch(FetchDescriptor<StoredSleepEvent>(predicate: activePredicate))
        let endedEvents = try modelContext.fetch(FetchDescriptor<StoredSleepEvent>(predicate: endedPredicate))
        return activeEvents + endedEvents
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

    private func fetchStoredBathEvent(id: UUID) throws -> StoredBathEvent? {
        let predicate = #Predicate<StoredBathEvent> { $0.id == id }
        return try modelContext.fetch(FetchDescriptor<StoredBathEvent>(predicate: predicate)).first
    }

    private func fetchStoredBreastFeedEvent(id: UUID) throws -> StoredBreastFeedEvent? {
        let predicate = #Predicate<StoredBreastFeedEvent> { $0.id == id }
        return try modelContext.fetch(FetchDescriptor<StoredBreastFeedEvent>(predicate: predicate)).first
    }

    private func fetchStoredBottleFeedEvent(id: UUID) throws -> StoredBottleFeedEvent? {
        let predicate = #Predicate<StoredBottleFeedEvent> { $0.id == id }
        return try modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>(predicate: predicate)).first
    }

    private func fetchStoredSleepEvent(id: UUID) throws -> StoredSleepEvent? {
        let predicate = #Predicate<StoredSleepEvent> { $0.id == id }
        return try modelContext.fetch(FetchDescriptor<StoredSleepEvent>(predicate: predicate)).first
    }

    private func fetchStoredNappyEvent(id: UUID) throws -> StoredNappyEvent? {
        let predicate = #Predicate<StoredNappyEvent> { $0.id == id }
        return try modelContext.fetch(FetchDescriptor<StoredNappyEvent>(predicate: predicate)).first
    }

    private func fetchStoredMedicationEvent(id: UUID) throws -> StoredMedicationEvent? {
        let predicate = #Predicate<StoredMedicationEvent> { $0.id == id }
        return try modelContext.fetch(FetchDescriptor<StoredMedicationEvent>(predicate: predicate)).first
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
