import SwiftUI
import UIKit

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
        .background(backgroundStyle, in: Capsule())
        .overlay {
            if isIncreaseContrastEnabled {
                Capsule()
                    .strokeBorder(.primary.opacity(0.28), lineWidth: 1)
            }
        }
        .shadow(color: .black.opacity(isReduceTransparencyEnabled ? 0.08 : 0.12), radius: isReduceTransparencyEnabled ? 2 : 4, y: 2)
        .accessibilityIdentifier("transient-message-banner")
    }

    private var backgroundStyle: AnyShapeStyle {
        isReduceTransparencyEnabled
            ? AnyShapeStyle(Color(.secondarySystemGroupedBackground))
            : AnyShapeStyle(.thinMaterial)
    }

    private var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    private var isIncreaseContrastEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }
}
