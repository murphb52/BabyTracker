import SwiftUI
import UIKit

public struct SyncIndicatorView: View {
    let state: SyncBannerState

    @State private var isSpinning = false

    public init(state: SyncBannerState) {
        self.state = state
    }

    public var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(symbolColor)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .frame(width: 38, height: 38)
            .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                if isIncreaseContrastEnabled {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(borderColor.opacity(0.35), lineWidth: 1)
                }
            }
            .shadow(color: .black.opacity(isReduceTransparencyEnabled ? 0.08 : 0.14), radius: isReduceTransparencyEnabled ? 6 : 10, y: 4)
            .contentTransition(.symbolEffect(.replace.downUp.wholeSymbol))
            .scaleEffect(1)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: state)
            .animation(
                state == .syncing
                    ? .linear(duration: 0.85).repeatForever(autoreverses: false)
                    : .default,
                value: isSpinning
            )
            .accessibilityElement()
            .accessibilityLabel(state.accessibilityLabel)
            .accessibilityIdentifier("app-sync-indicator")
            .onAppear {
                updateSpinState()
            }
            .onChange(of: state) { _, _ in
                updateSpinState()
            }
    }

    private var backgroundStyle: AnyShapeStyle {
        isReduceTransparencyEnabled
            ? AnyShapeStyle(Color(.secondarySystemGroupedBackground))
            : AnyShapeStyle(.ultraThinMaterial)
    }

    private var symbolName: String {
        switch state {
        case .syncing:
            "arrow.triangle.2.circlepath"
        case .synced:
            "checkmark"
        case .lastSyncFailed:
            "xmark"
        }
    }

    private var symbolColor: Color {
        switch state {
        case .syncing:
            .accentColor
        case .synced:
            .green
        case .lastSyncFailed:
            .red
        }
    }

    private var borderColor: Color {
        switch state {
        case .syncing:
            .accentColor
        case .synced:
            .green
        case .lastSyncFailed:
            .red
        }
    }

    private func updateSpinState() {
        if state == .syncing {
            isSpinning = false
            isSpinning = true
        } else {
            isSpinning = false
        }
    }

    private var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    private var isIncreaseContrastEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }
}

#Preview("Syncing") {
    SyncIndicatorView(state: .syncing)
        .padding()
}

#Preview("Synced") {
    SyncIndicatorView(state: .synced)
        .padding()
}

#Preview("Failed") {
    SyncIndicatorView(state: .lastSyncFailed("Sync failed. Local changes are still saved."))
        .padding()
}
