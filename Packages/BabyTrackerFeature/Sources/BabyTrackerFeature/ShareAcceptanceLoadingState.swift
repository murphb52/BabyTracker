import Foundation

public struct ShareAcceptanceLoadingState: Equatable, Sendable {
    public let title: String
    public let message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    public static let acceptingSharedChild = ShareAcceptanceLoadingState(
        title: "Accepting Shared Child...",
        message: "We're accepting the iCloud share and downloading the child's data now."
    )
}
