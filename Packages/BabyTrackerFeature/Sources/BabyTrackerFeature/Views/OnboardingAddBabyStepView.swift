import SwiftUI

/// The baby setup step in the interactive onboarding flow.
/// Collects baby name and optional birth date before the user logs their first event.
struct OnboardingAddBabyStepView: View {
    @Binding var childName: String
    @Binding var includesBirthDate: Bool
    @Binding var birthDate: Date
    let addAction: () -> Void
    let skipAction: () -> Void

    private var trimmedName: String {
        childName.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Now let's add your baby")
                        .font(.largeTitle.weight(.bold))

                    Text("You can always update this from the Profile tab.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Baby's name")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    TextField("e.g. Olivia", text: $childName)
                        .font(.title3)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .accessibilityIdentifier("onboarding-baby-name-field")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Add birth date", isOn: $includesBirthDate)
                        .font(.body.weight(.medium))

                    if includesBirthDate {
                        DatePicker(
                            "Birth date",
                            selection: $birthDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: includesBirthDate)
                .padding(20)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onSubmit {
            guard !trimmedName.isEmpty else { return }
            addAction()
        }
    }
}

#Preview {
    @Previewable @State var name = ""
    @Previewable @State var includesBirthDate = false
    @Previewable @State var birthDate = Date()

    OnboardingAddBabyStepView(
        childName: $name,
        includesBirthDate: $includesBirthDate,
        birthDate: $birthDate,
        addAction: {},
        skipAction: {}
    )
}
