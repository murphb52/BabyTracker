import Foundation

@MainActor
public protocol LiveActivityPreferenceStore: AnyObject {
    var isLiveActivityEnabled: Bool { get }
    func setLiveActivityEnabled(_ isEnabled: Bool)
}
