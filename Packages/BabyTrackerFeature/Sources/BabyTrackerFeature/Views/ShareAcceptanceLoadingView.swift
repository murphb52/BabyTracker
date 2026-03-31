import SwiftUI

public struct ShareAcceptanceLoadingView: View {
    let state: ShareAcceptanceLoadingState

    public init(state: ShareAcceptanceLoadingState) {
        self.state = state
    }

    public var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .controlSize(.large)

            VStack(spacing: 12) {
                Text(state.title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(state.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(Color(.systemGroupedBackground))
        .accessibilityIdentifier("share-acceptance-loading-screen")
    }
}
