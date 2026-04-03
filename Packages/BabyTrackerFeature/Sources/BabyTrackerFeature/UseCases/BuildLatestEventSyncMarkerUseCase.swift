import BabyTrackerDomain
import Foundation

/// Returns an `EventSyncMarkerViewState` for the most-recently-updated event,
/// or `nil` if the event list is empty.
public enum BuildLatestEventSyncMarkerUseCase {
    public static func execute(events: [BabyEvent]) -> EventSyncMarkerViewState? {
        events.max { left, right in
            if left.metadata.updatedAt != right.metadata.updatedAt {
                return left.metadata.updatedAt < right.metadata.updatedAt
            }
            return left.id.uuidString < right.id.uuidString
        }.map(EventSyncMarkerViewState.init)
    }
}
