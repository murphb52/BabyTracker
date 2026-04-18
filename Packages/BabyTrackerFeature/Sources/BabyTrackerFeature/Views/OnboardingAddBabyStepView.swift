import SwiftUI

/// The baby setup step in the interactive onboarding flow.
/// Collects baby name and optional birth date before the user logs their first event.
struct OnboardingAddBabyStepView: View {
    @Binding var childName: String
    @Binding var includesBirthDate: Bool
    @Binding var birthDate: Date
    let addAction: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appearedMask: [Bool] = [false, false, false, false]

    private var trimmedName: String {
        childName.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AnimatedSymbolSceneView(symbolNames: [
                    "teddybear.fill",
                    "moon.zzz.fill",
                    "heart.fill",
                ])

                VStack(alignment: .leading, spacing: 12) {
                    Text("Now let's add your baby")
                        .font(.largeTitle.weight(.bold))
                        .opacity(appearedMask[0] ? 1 : 0)
                        .offset(y: appearedMask[0] ? 0 : 18)

                    Text("You can always update this from the Profile tab.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(appearedMask[1] ? 1 : 0)
                        .offset(y: appearedMask[1] ? 0 : 14)
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
                .opacity(appearedMask[2] ? 1 : 0)
                .offset(y: appearedMask[2] ? 0 : 14)

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
                .opacity(appearedMask[3] ? 1 : 0)
                .offset(y: appearedMask[3] ? 0 : 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            staggerIn()
        }
        .onSubmit {
            guard !trimmedName.isEmpty else { return }
            addAction()
        }
    }

    private func staggerIn() {
        if reduceMotion {
            appearedMask = Array(repeating: true, count: appearedMask.count)
            return
        }
        for index in 0..<appearedMask.count {
            let delay = Double(index) * 0.09
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(delay)) {
                appearedMask[index] = true
            }
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
        addAction: {}
    )
}
