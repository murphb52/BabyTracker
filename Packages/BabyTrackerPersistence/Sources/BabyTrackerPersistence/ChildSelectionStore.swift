import Foundation

/// Stores the user's currently selected child ID as a local UI preference.
@MainActor
public protocol ChildSelectionStore: AnyObject {
    func loadSelectedChildID() -> UUID?
    func saveSelectedChildID(_ childID: UUID?)
}
