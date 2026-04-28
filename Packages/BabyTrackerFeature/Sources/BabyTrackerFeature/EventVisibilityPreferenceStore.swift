import BabyTrackerDomain
import Foundation

@MainActor
public protocol EventVisibilityPreferenceStore: AnyObject {
    var enabledEventKinds: Set<BabyEventKind> { get }
    func setEnabledEventKinds(_ kinds: Set<BabyEventKind>)
}
