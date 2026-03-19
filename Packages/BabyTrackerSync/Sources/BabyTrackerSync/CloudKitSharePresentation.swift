import CloudKit
import Foundation

public struct CloudKitSharePresentation: Sendable {
    public let share: CKShare
    public let container: CKContainer

    public init(share: CKShare, container: CKContainer) {
        self.share = share
        self.container = container
    }
}
