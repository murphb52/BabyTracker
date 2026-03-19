import BabyTrackerSync
import Foundation

public struct ShareSheetState: Identifiable, Sendable {
    public let id = UUID()
    public let presentation: CloudKitSharePresentation

    public init(presentation: CloudKitSharePresentation) {
        self.presentation = presentation
    }
}
