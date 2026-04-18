import SwiftUI
import UIKit

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
        .background(backgroundStyle, in: Capsule())
        .overlay {
            if isIncreaseContrastEnabled {
                Capsule()
                    .strokeBorder(.primary.opacity(0.28), lineWidth: 1)
            }
        }
        .shadow(color: .black.opacity(isReduceTransparencyEnabled ? 0.08 : 0.12), radius: isReduceTransparencyEnabled ? 2 : 4, y: 2)
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
