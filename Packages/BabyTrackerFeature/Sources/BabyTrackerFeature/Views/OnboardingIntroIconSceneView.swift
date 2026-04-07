import SwiftUI

struct OnboardingIntroIconSceneView: View {
    let page: OnboardingIntroPage

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize = 56

    @State private var currentSymbolIndex = 0
    @State private var symbolAnimationTrigger = 0
    @State private var isFloating = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.16),
                            Color.accentColor.opacity(0.06),
                            Color(.secondarySystemBackground),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 116, height: 116)
                .blur(radius: 18)
                .offset(x: -48, y: -34)

            OnboardingIntroAccentSymbolView(
                symbolName: leadingAccentSymbolName,
                baseOffset: CGSize(width: -68, height: 42),
                floatingOffset: CGSize(width: -78, height: 28),
                isFloating: isFloating,
                isDrawing: reduceMotion == false
            )

            OnboardingIntroAccentSymbolView(
                symbolName: trailingAccentSymbolName,
                baseOffset: CGSize(width: 72, height: -48),
                floatingOffset: CGSize(width: 82, height: -62),
                isFloating: isFloating,
                isDrawing: reduceMotion == false
            )

            Image(systemName: currentSymbolName)
                .font(.system(size: symbolSize, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .contentTransition(.symbolEffect(.replace.downUp.wholeSymbol))
                .symbolEffect(.bounce.down.byLayer, value: symbolAnimationTrigger)
                .shadow(color: Color.accentColor.opacity(0.18), radius: 12, y: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 196)
        .clipped()
        .accessibilityHidden(true)
        .task(id: animationTaskID) {
            guard reduceMotion == false else {
                currentSymbolIndex = 0
                symbolAnimationTrigger = 0
                isFloating = false
                return
            }

            currentSymbolIndex = 0
            symbolAnimationTrigger = 1
            isFloating = false

            withAnimation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true)) {
                isFloating = true
            }

            guard page.symbolNames.count > 1 else {
                return
            }

            while Task.isCancelled == false {
                try? await Task.sleep(for: .seconds(1.5))

                guard Task.isCancelled == false else {
                    return
                }

                await MainActor.run {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                        currentSymbolIndex = (currentSymbolIndex + 1) % page.symbolNames.count
                    }
                    symbolAnimationTrigger += 1
                }
            }
        }
    }

    private var animationTaskID: String {
        "\(page.id)-\(reduceMotion)"
    }

    private var currentSymbolName: String {
        page.symbolNames[currentSymbolIndex]
    }

    private var leadingAccentSymbolName: String {
        guard page.symbolNames.count > 1 else {
            return currentSymbolName
        }

        return page.symbolNames[1]
    }

    private var trailingAccentSymbolName: String {
        guard let trailingSymbolName = page.symbolNames.last else {
            return currentSymbolName
        }

        return trailingSymbolName
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
