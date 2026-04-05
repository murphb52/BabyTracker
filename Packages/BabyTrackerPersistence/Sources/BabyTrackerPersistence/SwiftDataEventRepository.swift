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
        case let .breastFeed(value):
            try saveBreastFeed(value)
        case let .bottleFeed(value):
            try saveBottleFeed(value)
        case let .sleep(value):
            try saveSleep(value)
        case let .nappy(value):
            try saveNappy(value)
        }

        try saveChanges()
    }

    public func loadEvent(id: UUID) throws -> BabyEvent? {
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

        return nil
    }

    public func loadTimeline(
        for childID: UUID,
        includingDeleted: Bool = false
    ) throws -> [BabyEvent] {
        var timeline: [BabyEvent] = []

        timeline.append(contentsOf: try modelContext.fetch(FetchDescriptor<StoredBreastFeedEvent>())
            .filter { storedEvent in
                storedEvent.childID == childID &&
                (
                    includingDeleted ||
                    !isSoftDeleted(
                        isDeleted: storedEvent.isDeleted,
                        deletedAt: storedEvent.deletedAt
                    )
                )
            }
            .map { .breastFeed(try mapBreastFeed($0)) })
        timeline.append(contentsOf: try modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>())
            .filter { storedEvent in
                storedEvent.childID == childID &&
                (
                    includingDeleted ||
                    !isSoftDeleted(
                        isDeleted: storedEvent.isDeleted,
                        deletedAt: storedEvent.deletedAt
                    )
                )
            }
            .map { .bottleFeed(try mapBottleFeed($0)) })
        timeline.append(contentsOf: try modelContext.fetch(FetchDescriptor<StoredSleepEvent>())
            .filter { storedEvent in
                storedEvent.childID == childID &&
                (
                    includingDeleted ||
                    !isSoftDeleted(
                        isDeleted: storedEvent.isDeleted,
                        deletedAt: storedEvent.deletedAt
                    )
                )
            }
            .map { .sleep(try mapSleep($0)) })
        timeline.append(contentsOf: try modelContext.fetch(FetchDescriptor<StoredNappyEvent>())
            .filter { storedEvent in
                storedEvent.childID == childID &&
                (
                    includingDeleted ||
                    !isSoftDeleted(
                        isDeleted: storedEvent.isDeleted,
                        deletedAt: storedEvent.deletedAt
                    )
                )
            }
            .map { .nappy(try mapNappy($0)) })

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

        return try loadTimeline(for: childID, includingDeleted: includingDeleted)
            .filter { event in
                eventOverlapsDay(event, startOfDay: startOfDay, endOfDay: endOfDay)
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
        case let .bottleFeed(feed):
            return feed.metadata.occurredAt >= startOfDay && feed.metadata.occurredAt < endOfDay
        case let .nappy(nappy):
            return nappy.metadata.occurredAt >= startOfDay && nappy.metadata.occurredAt < endOfDay
        }
    }

    public func loadActiveSleepEvent(for childID: UUID) throws -> SleepEvent? {
        try modelContext.fetch(FetchDescriptor<StoredSleepEvent>())
            .filter { storedEvent in
                storedEvent.childID == childID &&
                !isSoftDeleted(
                    isDeleted: storedEvent.isDeleted,
                    deletedAt: storedEvent.deletedAt
                ) &&
                storedEvent.endedAt == nil
            }
            .map(mapSleep)
            .sorted { left, right in left.startedAt > right.startedAt }
            .first
    }

    public func softDeleteEvent(
        id: UUID,
        deletedAt: Date,
        deletedBy: UUID
    ) throws {
        if let storedEvent = try fetchStoredBreastFeedEvent(id: id) {
            markDeleted(storedEvent, deletedAt: deletedAt, deletedBy: deletedBy)
        } else if let storedEvent = try fetchStoredBottleFeedEvent(id: id) {
            markDeleted(storedEvent, deletedAt: deletedAt, deletedBy: deletedBy)
        } else if let storedEvent = try fetchStoredSleepEvent(id: id) {
            markDeleted(storedEvent, deletedAt: deletedAt, deletedBy: deletedBy)
        } else if let storedEvent = try fetchStoredNappyEvent(id: id) {
            markDeleted(storedEvent, deletedAt: deletedAt, deletedBy: deletedBy)
        }

        try saveChanges()
    }

    private var modelContext: ModelContext {
        store.modelContainer.mainContext
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

    private func fetchStoredBreastFeedEvent(id: UUID) throws -> StoredBreastFeedEvent? {
        try modelContext.fetch(FetchDescriptor<StoredBreastFeedEvent>())
            .first { $0.id == id }
    }

    private func fetchStoredBottleFeedEvent(id: UUID) throws -> StoredBottleFeedEvent? {
        try modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>())
            .first { $0.id == id }
    }

    private func fetchStoredSleepEvent(id: UUID) throws -> StoredSleepEvent? {
        try modelContext.fetch(FetchDescriptor<StoredSleepEvent>())
            .first { $0.id == id }
    }

    private func fetchStoredNappyEvent(id: UUID) throws -> StoredNappyEvent? {
        try modelContext.fetch(FetchDescriptor<StoredNappyEvent>())
            .first { $0.id == id }
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
