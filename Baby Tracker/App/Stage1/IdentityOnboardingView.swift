import BabyTrackerFeature
import SwiftUI

struct IdentityOnboardingView: View {
    let model: AppModel

    @State private var displayName = ""

    private var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)

                    Text("Baby Tracker")
                        .font(.largeTitle.weight(.bold))

                    Text("What should we call you?")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(height: 40)

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
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                        .accessibilityIdentifier("identity-name-field")
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 24)

                Button {
                    model.createLocalUser(displayName: trimmedName)
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmedName.isEmpty)
                .padding(.horizontal, 32)
                .accessibilityIdentifier("identity-save-button")

                Spacer()
                Spacer()
            }
        }
        .onSubmit {
            guard !trimmedName.isEmpty else { return }
            model.createLocalUser(displayName: trimmedName)
        }
    }
}
