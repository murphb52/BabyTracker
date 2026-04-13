import SwiftUI

struct IdentityOnboardingNameStepView: View {
    @Binding var displayName: String
    let submitAction: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AnimatedSymbolSceneView(symbolNames: [
                    "person.crop.circle.fill",
                    "heart.fill",
                    "figure.and.child.holdinghands",
                ])

                VStack(alignment: .leading, spacing: 12) {
                    Text("Let’s set up your profile")
                        .font(.largeTitle.weight(.bold))

                    Text("Start with your name. You can add your first child right after this.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your name")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    TextField("e.g. Sarah", text: $displayName)
                        .font(.title3)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .accessibilityIdentifier("identity-name-field")
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Next up")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text("You’ll go straight into creating your first child profile.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onSubmit {
            submitAction()
        }
    }
}

#Preview {
    IdentityOnboardingNameStepView(
        displayName: .constant("Alex"),
        submitAction: {}
    )
}
