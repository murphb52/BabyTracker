import SwiftUI

struct Stage1ErrorBannerView: View {
    let message: String
    let dismissAction: () -> Void

    var body: some View {
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
        .accessibilityIdentifier("stage1-error-banner")
    }
}
