import SwiftUI

public struct ShareAcceptanceLoadingView: View {
    let state: ShareAcceptanceLoadingState
    let continueAction: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var symbolIndex = 0
    @State private var symbolAnimationTrigger = 0

    private let symbolNames = [
        "person.crop.circle.badge.checkmark",
        "arrow.triangle.2.circlepath.circle.fill",
        "externaldrive.badge.icloud.fill",
    ]

    public init(
        state: ShareAcceptanceLoadingState,
        continueAction: @escaping () -> Void = {}
    ) {
        self.state = state
        self.continueAction = continueAction
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground),
                    Color.accentColor.opacity(0.1),
                    Color(.systemGroupedBackground),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                iconScene

                VStack(spacing: 12) {
                    Text(state.title)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(state.message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                statusCard

                if state.phase == .completed {
                    Button("Continue", action: continueAction)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("share-acceptance-continue-button")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .accessibilityIdentifier("share-acceptance-loading-screen")
    }

    private var iconScene: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.18),
                            Color.accentColor.opacity(0.08),
                            Color(.secondarySystemBackground),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 120, height: 120)
                .blur(radius: 18)
                .offset(x: -48, y: -28)

            Image(systemName: symbolNames[symbolIndex])
                .font(.system(size: 58, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .contentTransition(.symbolEffect(.replace.downUp.wholeSymbol))
                .symbolEffect(.bounce.down.byLayer, value: symbolAnimationTrigger)
                .shadow(color: Color.accentColor.opacity(0.2), radius: 12, y: 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 196)
        .task(id: "\(state.phase)-\(reduceMotion)") {
            guard reduceMotion == false else {
                symbolIndex = 0
                symbolAnimationTrigger = 0
                return
            }

            symbolIndex = 0
            symbolAnimationTrigger = 1

            guard state.phase == .syncing else {
                return
            }

            while Task.isCancelled == false {
                try? await Task.sleep(for: .seconds(1.5))

                guard Task.isCancelled == false else {
                    return
                }

                await MainActor.run {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                        symbolIndex = (symbolIndex + 1) % symbolNames.count
                    }
                    symbolAnimationTrigger += 1
                }
            }
        }
    }

    private var statusCard: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.thinMaterial)
            .overlay(alignment: .leading) {
                HStack(spacing: 14) {
                    if state.phase == .syncing {
                        ProgressView()
                            .controlSize(.large)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.phase == .syncing ? "Syncing shared timeline" : "Sync complete")
                            .font(.headline)
                        Text(state.phase == .syncing ? "Large histories can take a minute or two." : "Your data is ready.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(18)
            }
            .frame(height: 92)
    }
}

#Preview("Syncing") {
    ShareAcceptanceLoadingView(state: .syncing(childName: "Poppy"))
}

#Preview("Completed") {
    ShareAcceptanceLoadingView(state: .completed(childName: "Poppy"))
}
