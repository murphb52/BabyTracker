import SwiftUI

struct OnboardingIntroHighlightBadge: View {
    let highlight: OnboardingIntroHighlight

    var body: some View {
        Label(highlight.title, systemImage: highlight.symbolName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    OnboardingIntroHighlightBadge(
        highlight: OnboardingIntroHighlight(
            title: "Shared handoffs",
            symbolName: "arrow.left.arrow.right.circle.fill"
        )
    )
    .padding()
}
