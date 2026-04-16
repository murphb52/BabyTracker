import SwiftUI

public struct NoChildrenView: View {
    let model: AppModel

    @State private var showingShareInstructions = false

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 10) {
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.system(size: 52, weight: .thin))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)

                    Text("No Children Yet")
                        .font(.title.weight(.bold))

                    Text("Add a child profile to get started,\nor get access from a partner.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 48)

                VStack(spacing: 12) {
                    NavigationLink {
                        ChildCreationView(model: model)
                    } label: {
                        optionCard(
                            icon: "plus.circle.fill",
                            title: "Add a Child",
                            subtitle: "Create a new child profile on this device"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("no-children-add-child-button")

                    Button {
                        showingShareInstructions = true
                    } label: {
                        optionCard(
                            icon: "person.2.fill",
                            title: "Get access from a partner",
                            subtitle: "Ask them to share their child profile with you"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("no-children-partner-share-button")
                }
                .padding(.horizontal, 24)

                Spacer()
                Spacer()
            }
        }
        .sheet(isPresented: $showingShareInstructions) {
            JoinChildShareInstructionsView()
        }
    }

    @ViewBuilder
    private func optionCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
    }
}
