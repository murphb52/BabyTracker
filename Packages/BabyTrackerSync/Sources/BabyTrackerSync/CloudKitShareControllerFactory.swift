import CloudKit
import Foundation
import UIKit

@MainActor
public protocol CloudKitShareControllerFactory {
    func makeShareController(
        share: CKShare,
        container: CKContainer,
        delegate: UICloudSharingControllerDelegate
    ) -> UICloudSharingController
}
