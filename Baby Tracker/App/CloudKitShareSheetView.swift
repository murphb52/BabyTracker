import BabyTrackerFeature
import BabyTrackerSync
import SwiftUI
import UIKit

struct CloudKitShareSheetView: UIViewControllerRepresentable {
    let shareState: ShareSheetState
    let childName: String

    func makeCoordinator() -> Coordinator {
        Coordinator(childName: childName)
    }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let factory = DefaultCloudKitShareControllerFactory()
        return factory.makeShareController(
            share: shareState.presentation.share,
            container: shareState.presentation.container,
            delegate: context.coordinator
        )
    }

    func updateUIViewController(
        _ uiViewController: UICloudSharingController,
        context: Context
    ) {}
}

extension CloudKitShareSheetView {
    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        private let childName: String

        init(childName: String) {
            self.childName = childName
        }

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {}

        func itemTitle(for csc: UICloudSharingController) -> String? {
            childName
        }

        func itemTitleForCloudSharingController(
            _ csc: UICloudSharingController
        ) -> String? {
            childName
        }
    }
}
