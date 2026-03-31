import SwiftUI

public struct TransientMessageBannerView: View {
    let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: Capsule())
        .shadow(radius: 4, y: 2)
        .accessibilityIdentifier("transient-message-banner")
    }
}
