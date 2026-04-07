import SwiftUI

struct OnboardingIntroStepView: View {
    let page: OnboardingIntroPage

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)

            OnboardingIntroIconSceneView(page: page)

            VStack(alignment: .leading, spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)

                Text(page.message)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 24)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    HStack(spacing: 16) {
                        ForEach(page.highlights) { highlight in
                            OnboardingIntroHighlightBadge(highlight: highlight)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 84)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

#Preview {
    OnboardingIntroStepView(
        page: OnboardingIntroPage(
            id: "preview",
            title: "Log it fast, find the pattern",
            message: "Capture what happened in seconds, then use the timeline and summary views to see what your baby actually needs.",
            symbolNames: ["square.and.pencil.circle.fill", "list.bullet.clipboard.fill", "chart.line.uptrend.xyaxis.circle.fill"],
            highlights: [
                OnboardingIntroHighlight(title: "Quick logging", symbolName: "checkmark.circle.fill"),
                OnboardingIntroHighlight(title: "Daily summaries", symbolName: "chart.bar.fill"),
            ]
        )
    )
}
