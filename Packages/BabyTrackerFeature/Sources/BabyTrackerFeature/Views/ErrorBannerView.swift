import SwiftUI

public struct ErrorBannerView: View {
    let message: String
    let dismissAction: () -> Void

    public init(
        message: String,
        dismissAction: @escaping () -> Void
    ) {
        self.message = message
        self.dismissAction = dismissAction
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Something went wrong")
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
            }

            Spacer()

            Button("Dismiss") {
                dismissAction()
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 8, y: 4)
        .accessibilityIdentifier("error-banner")
    }
}
