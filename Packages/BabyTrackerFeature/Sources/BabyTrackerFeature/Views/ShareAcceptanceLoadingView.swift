import SwiftUI

public struct ShareAcceptanceLoadingView: View {
    let state: ShareAcceptanceLoadingState
    let continueAction: () -> Void
    @ScaledMetric(relativeTo: .title3) private var copySectionHeight = 176

    private let symbolNames = [
        "person.crop.circle.badge.checkmark",
        "arrow.triangle.2.circlepath.circle.fill",
        "icloud.and.arrow.down.fill",
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

            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 24)

                iconScene

                VStack(alignment: .leading, spacing: 12) {
                    Text(state.title)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(state.message)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: copySectionHeight, alignment: .topLeading)

                statusCard

                if state.phase == .completed {
                    Button("Continue", action: continueAction)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("share-acceptance-continue-button")
                }

                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .accessibilityIdentifier("share-acceptance-loading-screen")
    }

    private var iconScene: some View {
        AnimatedSymbolSceneView(symbolNames: symbolNames)
    }

    private var statusCard: some View {
        HStack(alignment: .top, spacing: 14) {
            if state.phase == .syncing {
                ProgressView()
                    .controlSize(.large)
                    .padding(.top, 2)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .padding(.top, 1)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(state.phase == .syncing ? "Syncing shared timeline" : "Sync complete")
                    .font(.headline)
                Text(state.phase == .syncing ? "Large histories can take a minute or two." : "Your data is ready.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Syncing") {
    ShareAcceptanceLoadingView(state: .syncing(childName: "Poppy"))
}

#Preview("Completed") {
    ShareAcceptanceLoadingView(state: .completed(childName: "Poppy"))
}
