import CloudKit
import Foundation
import UIKit

@MainActor
public struct DefaultCloudKitShareControllerFactory: CloudKitShareControllerFactory {
    public init() {}

    public func makeShareController(
        share: CKShare,
        container: CKContainer,
        delegate: UICloudSharingControllerDelegate
    ) -> UICloudSharingController {
        let controller = UICloudSharingController(
            share: share,
            container: container
        )
        controller.delegate = delegate
        controller.availablePermissions = [
            .allowPrivate,
            .allowReadWrite,
        ]
        return controller
    }
}
