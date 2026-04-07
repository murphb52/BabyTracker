import SwiftUI

struct OnboardingIntroHighlightBadge: View {
    let highlight: OnboardingIntroHighlight

    var body: some View {
        Label(highlight.title, systemImage: highlight.symbolName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
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
