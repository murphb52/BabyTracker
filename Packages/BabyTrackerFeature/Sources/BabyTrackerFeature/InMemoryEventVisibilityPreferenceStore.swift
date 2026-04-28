import BabyTrackerDomain
import Foundation

@MainActor
public final class InMemoryEventVisibilityPreferenceStore: EventVisibilityPreferenceStore {
    public var enabledEventKinds: Set<BabyEventKind>

    public init(enabledEventKinds: Set<BabyEventKind> = Set(BabyEventKind.allCases)) {
        self.enabledEventKinds = enabledEventKinds
    }

    public func setEnabledEventKinds(_ kinds: Set<BabyEventKind>) {
        enabledEventKinds = kinds
    }
}
