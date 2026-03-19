import Foundation

public enum ChildAccessAction: Sendable {
    case viewChild
    case logEvent
    case editEvent
    case deleteEvent
    case editChild
    case archiveChild
    case restoreChild
    case inviteCaregiver
    case removeCaregiver
}
