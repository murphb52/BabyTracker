import SwiftUI

struct UndoBannerView: View {
    let message: String
    let undoAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Spacer()

            Button("Undo") {
                undoAction()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("undo-delete-button")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: Capsule())
        .shadow(radius: 4, y: 2)
    }
}
