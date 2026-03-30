import BabyTrackerSync
import SwiftUI
import UIKit

public struct CloudKitShareSheetView: UIViewControllerRepresentable {
    let shareState: ShareSheetState
    let childName: String
    let onSaveFailure: (Error) -> Void

    public init(
        shareState: ShareSheetState,
        childName: String,
        onSaveFailure: @escaping (Error) -> Void
    ) {
        self.shareState = shareState
        self.childName = childName
        self.onSaveFailure = onSaveFailure
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            childName: childName,
            onSaveFailure: onSaveFailure
        )
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
        private let onSaveFailure: (Error) -> Void

        public init(
            childName: String,
            onSaveFailure: @escaping (Error) -> Void
        ) {
            self.childName = childName
            self.onSaveFailure = onSaveFailure
        }

        public func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            onSaveFailure(error)
        }

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
