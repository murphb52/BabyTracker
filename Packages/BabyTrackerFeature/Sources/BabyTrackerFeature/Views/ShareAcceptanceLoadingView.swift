import SwiftUI

public struct ShareAcceptanceLoadingView: View {
    let state: ShareAcceptanceLoadingState
    let continueAction: () -> Void

    public init(
        state: ShareAcceptanceLoadingState,
        continueAction: @escaping () -> Void = {}
    ) {
        self.state = state
        self.continueAction = continueAction
    }

    public var body: some View {
        VStack(spacing: 24) {
            iconScene

            VStack(spacing: 12) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if state.phase == .syncing {
                ProgressView("Syncing data…")
                    .controlSize(.large)
                    .padding(.top, 8)
            } else {
                Button("Continue", action: continueAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, 8)
                    .accessibilityIdentifier("share-acceptance-continue-button")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(Color(.systemGroupedBackground))
        .accessibilityIdentifier("share-acceptance-loading-screen")
    }

    private var iconScene: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.16),
                            Color.accentColor.opacity(0.06),
                            Color(.secondarySystemBackground),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 116, height: 116)
                .blur(radius: 18)
                .offset(x: -48, y: -34)

            Image(systemName: symbolName)
                .font(.system(size: 58, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .shadow(color: Color.accentColor.opacity(0.18), radius: 12, y: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 196)
        .accessibilityHidden(true)
    }

    private var title: String {
        switch state.phase {
        case .syncing:
            return "Invitation accepted for \(state.childName)"
        case .readyToContinue:
            return "\(state.childName) is ready"
        }
    }

    private var message: String {
        switch state.phase {
        case .syncing:
            return "We’re syncing your child’s profile, events, and memberships now. This can take a little while when there’s a lot of history."
        case .readyToContinue:
            return "We finished syncing your data. Continue to open the child profile."
        }
    }

    private var symbolName: String {
        switch state.phase {
        case .syncing:
            return "arrow.trianglehead.2.clockwise.icloud.fill"
        case .readyToContinue:
            return "checkmark.circle.fill"
        }
    }
}

#Preview("Syncing") {
    ShareAcceptanceLoadingView(
        state: ShareAcceptanceLoadingState(childName: "Poppy", phase: .syncing)
    )
}

#Preview("Ready") {
    ShareAcceptanceLoadingView(
        state: ShareAcceptanceLoadingState(childName: "Poppy", phase: .readyToContinue)
    )
}
