import BabyTrackerDomain
import BabyTrackerPersistence
import Foundation

/// In-memory test double for EventRepository.
/// Supports save, load, timeline queries, active-sleep lookup, and soft-delete.
@MainActor
final class InMemoryEventRepository: EventRepository {
    private let store: InMemoryStore

    init(store: InMemoryStore) {
        self.store = store
    }

    func saveEvent(_ event: BabyEvent) throws {
        store.events[event.id] = event
        store.syncStates[event.id] = SyncStateEntry(
            reference: SyncRecordReference(
                recordType: syncRecordType(for: event),
                recordID: event.id,
                childID: event.metadata.childID
            ),
            state: .pendingSync
        )
    }

    func loadEvent(id: UUID) throws -> BabyEvent? {
        store.events[id]
    }

    func loadTimeline(for childID: UUID, includingDeleted: Bool) throws -> [BabyEvent] {
        store.events.values
            .filter { $0.metadata.childID == childID && (includingDeleted || !$0.metadata.isDeleted) }
            .sorted { $0.metadata.occurredAt > $1.metadata.occurredAt }
    }

    func loadEvents(
        for childID: UUID,
        on day: Date,
        calendar: Calendar,
        includingDeleted: Bool
    ) throws -> [BabyEvent] {
        store.events.values
            .filter { event in
                event.metadata.childID == childID &&
                (includingDeleted || !event.metadata.isDeleted) &&
                calendar.isDate(event.metadata.occurredAt, inSameDayAs: day)
            }
            .sorted { $0.metadata.occurredAt > $1.metadata.occurredAt }
    }

    func loadActiveSleepEvent(for childID: UUID) throws -> SleepEvent? {
        for event in store.events.values {
            if case let .sleep(sleepEvent) = event,
               sleepEvent.metadata.childID == childID,
               sleepEvent.endedAt == nil,
               !sleepEvent.metadata.isDeleted {
                return sleepEvent
            }
        }
        return nil
    }

    func softDeleteEvent(id: UUID, deletedAt: Date, deletedBy: UUID) throws {
        guard let event = store.events[id] else { return }
        switch event {
        case var .breastFeed(e):
            e.metadata.markDeleted(at: deletedAt, by: deletedBy)
            store.events[id] = .breastFeed(e)
        case var .bottleFeed(e):
            e.metadata.markDeleted(at: deletedAt, by: deletedBy)
            store.events[id] = .bottleFeed(e)
        case var .sleep(e):
            e.metadata.markDeleted(at: deletedAt, by: deletedBy)
            store.events[id] = .sleep(e)
        case var .nappy(e):
            e.metadata.markDeleted(at: deletedAt, by: deletedBy)
            store.events[id] = .nappy(e)
        }
        store.syncStates[id]?.state = .pendingSync
    }

    private func syncRecordType(for event: BabyEvent) -> SyncRecordType {
        switch event {
        case .breastFeed: return .breastFeedEvent
        case .bottleFeed: return .bottleFeedEvent
        case .sleep: return .sleepEvent
        case .nappy: return .nappyEvent
        }
    }
}
