import Foundation

public enum ChildAccessPolicy {
    public static func canPerform(
        _ action: ChildAccessAction,
        membership: Membership?
    ) -> Bool {
        switch action {
        case .viewChild:
            membership?.status.hasSharedDataAccess == true
        case .editChild, .archiveChild, .restoreChild, .inviteCaregiver, .activateCaregiver, .removeCaregiver:
            isActiveOwner(membership)
        }
    }

    public static func isActiveOwner(_ membership: Membership?) -> Bool {
        membership?.role == .owner && membership?.status == .active
    }
}
