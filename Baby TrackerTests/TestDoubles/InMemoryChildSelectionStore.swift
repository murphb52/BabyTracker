import BabyTrackerDomain
import Foundation

/// In-memory test double for ChildSelectionStore.
/// Replaces UserDefaultsChildSelectionStore so tests don't touch real UserDefaults.
@MainActor
final class InMemoryChildSelectionStore: ChildSelectionStore {
    private let store: InMemoryStore

    init(store: InMemoryStore) {
        self.store = store
    }

    func loadSelectedChildID() -> UUID? {
        store.selectedChildID
    }

    func saveSelectedChildID(_ childID: UUID?) {
        store.selectedChildID = childID
    }
}
