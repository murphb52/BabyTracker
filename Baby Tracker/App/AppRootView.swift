import BabyTrackerFeature
import SwiftUI

struct AppRootView: View {
    let container: AppContainer

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "figure.and.child.holdinghands")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                Text(container.rootState.title)
                    .font(.title2.weight(.semibold))
                    .accessibilityIdentifier("foundation-title")

                Text(container.rootState.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("foundation-message")

                Text(container.rootState.stageMessage)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("foundation-stage-message")

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Baby Tracker")
        }
    }
}

#Preview {
    AppRootView(container: .live)
}
