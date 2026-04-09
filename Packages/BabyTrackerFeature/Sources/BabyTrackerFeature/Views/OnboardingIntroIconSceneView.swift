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
            title: "When every hour blurs together",
            message: "Feeds, nappies, and short naps are hard to keep straight when you're already exhausted.",
            symbolNames: ["clock.badge.questionmark.fill", "drop.fill", "moon.zzz.fill"],
            highlights: [
                OnboardingIntroHighlight(title: "Last feed", symbolName: "drop.fill"),
                OnboardingIntroHighlight(title: "Last sleep", symbolName: "moon.zzz.fill"),
            ]
        )
    )
    .padding()
}
