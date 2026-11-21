import SwiftUI

/// Shown under every conversation. The on-device model can be wrong, and
/// parents must never treat its answers as medical advice.
struct AskDisclaimerFooterView: View {
    var body: some View {
        Text("Answers are generated on this device and can be wrong. This is not medical advice. Contact your GP or health visitor with any concerns.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .accessibilityIdentifier("ask-disclaimer")
    }
}

#Preview {
    AskDisclaimerFooterView()
}
