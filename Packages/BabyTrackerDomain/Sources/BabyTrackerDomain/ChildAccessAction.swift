import Foundation

public enum ChildAccessAction: Sendable {
    case viewChild
    case logEvent
    case editChild
    case archiveChild
    case restoreChild
    case inviteCaregiver
    case removeCaregiver
}
