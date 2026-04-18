import SwiftUI

struct OnboardingIntroIconSceneView: View {
    let page: OnboardingIntroPage

    var body: some View {
        AnimatedSymbolSceneView(symbolNames: page.symbolNames)
    }
}

#Preview {
    OnboardingIntroIconSceneView(
        page: OnboardingIntroPage(
            id: "pain-points",
            title: "When you're tired and remembering is hard",
            message: "Feeds, nappies, and short stretches of sleep are easy to lose track of when you're exhausted with a baby.",
            symbolNames: ["clock.badge.questionmark.fill", "drop.fill", "moon.zzz.fill"],
            highlights: [
                OnboardingIntroHighlight(title: "Last feed", symbolName: "drop.fill"),
                OnboardingIntroHighlight(title: "Last sleep", symbolName: "moon.zzz.fill"),
            ]
        )
    )
    .padding()
}
