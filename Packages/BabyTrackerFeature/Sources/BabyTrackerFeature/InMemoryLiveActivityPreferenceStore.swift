import Foundation

@MainActor
public final class InMemoryLiveActivityPreferenceStore: LiveActivityPreferenceStore {
    public var isLiveActivityEnabled: Bool

    public init(isLiveActivityEnabled: Bool = true) {
        self.isLiveActivityEnabled = isLiveActivityEnabled
    }

    public func setLiveActivityEnabled(_ isEnabled: Bool) {
        isLiveActivityEnabled = isEnabled
    }
}
