import SwiftUI

public struct EventVisibilitySettingsView: View {
    let model: AppModel

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose what you'd like to track")
                        .font(.title2.weight(.bold))

                    Text("Turn event types on or off across the app. Your existing data stays safe, and you can re-enable any event again whenever you need it.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                EventTypeChecklistCardView(
                    model: model,
                    animateOnAppear: false
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle("Customize Events")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EventVisibilitySettingsView(model: ChildProfilePreviewFactory.makeModel())
    }
}
