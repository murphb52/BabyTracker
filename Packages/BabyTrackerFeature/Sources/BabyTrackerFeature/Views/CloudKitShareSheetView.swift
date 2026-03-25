import BabyTrackerSync
import SwiftUI
import UIKit

public struct CloudKitShareSheetView: UIViewControllerRepresentable {
    let shareState: ShareSheetState
    let childName: String

    public init(shareState: ShareSheetState, childName: String) {
        self.shareState = shareState
        self.childName = childName
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(childName: childName)
    }

    public func makeUIViewController(context: Context) -> UICloudSharingController {
        let factory = DefaultCloudKitShareControllerFactory()
        return factory.makeShareController(
            share: shareState.presentation.share,
            container: shareState.presentation.container,
            delegate: context.coordinator
        )
    }

    public func updateUIViewController(
        _ uiViewController: UICloudSharingController,
        context: Context
    ) {}
}

extension CloudKitShareSheetView {
    public final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        private let childName: String

        public init(childName: String) {
            self.childName = childName
        }

        public func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {}

        public func itemTitle(for csc: UICloudSharingController) -> String? {
            childName
        }

        public func itemTitleForCloudSharingController(
            _ csc: UICloudSharingController
        ) -> String? {
            childName
        }
    }
}
