import SwiftUI

struct OnboardingPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled = false

    private static let verticalPadding: CGFloat = 4

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Self.verticalPadding)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 12) {
        OnboardingPrimaryButton(title: "Continue", action: {})
        OnboardingPrimaryButton(title: "Add Baby", action: {}, isDisabled: true)
    }
    .padding()
}
