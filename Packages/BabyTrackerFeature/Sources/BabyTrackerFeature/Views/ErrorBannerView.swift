import SwiftUI
import UIKit

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
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            if isIncreaseContrastEnabled {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.primary.opacity(0.28), lineWidth: 1)
            }
        }
        .shadow(color: .black.opacity(isReduceTransparencyEnabled ? 0.08 : 0.14), radius: isReduceTransparencyEnabled ? 4 : 8, y: 4)
        .accessibilityIdentifier("error-banner")
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
