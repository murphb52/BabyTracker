import SwiftUI

struct AnimatedSymbolSceneView: View {
    let symbolNames: [String]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize = 56

    @State private var currentSymbolIndex = 0
    @State private var symbolAnimationTrigger = 0

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
                .fill(glowColor)
                .frame(width: 116, height: 116)
                .blur(radius: glowBlurRadius)
                .offset(x: -48, y: -34)

            Image(systemName: currentSymbolName)
                .font(.system(size: symbolSize, weight: .semibold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(symbolPrimaryColor, symbolSecondaryColor)
                .contentTransition(.symbolEffect(.replace.downUp.wholeSymbol))
                .symbolEffect(.bounce.down.byLayer, value: symbolAnimationTrigger)
                .shadow(color: symbolShadowColor, radius: 12, y: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 196)
        .clipped()
        .accessibilityHidden(true)
        .task(id: animationTaskID) {
            guard reduceMotion == false else {
                currentSymbolIndex = 0
                symbolAnimationTrigger = 0
                return
            }

            currentSymbolIndex = 0
            symbolAnimationTrigger = 1

            guard symbolNames.count > 1 else {
                return
            }

            while Task.isCancelled == false {
                try? await Task.sleep(for: .seconds(1.5))

                guard Task.isCancelled == false else {
                    return
                }

                await MainActor.run {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                        currentSymbolIndex = (currentSymbolIndex + 1) % symbolNames.count
                    }
                    symbolAnimationTrigger += 1
                }
            }
        }
    }

    private var animationTaskID: String {
        "\(symbolNames.joined(separator: "-"))-\(reduceMotion)"
    }

    private var currentSymbolName: String {
        guard symbolNames.isEmpty == false else {
            return "questionmark.circle"
        }

        return symbolNames[currentSymbolIndex]
    }

    private var glowColor: Color {
        switch colorScheme {
        case .dark:
            return Color.accentColor.opacity(0.16)
        case .light:
            return Color.white.opacity(0.4)
        @unknown default:
            return Color.white.opacity(0.4)
        }
    }

    private var glowBlurRadius: CGFloat {
        colorScheme == .dark ? 26 : 18
    }

    private var symbolPrimaryColor: Color {
        colorScheme == .dark ? .white : Color.accentColor
    }

    private var symbolSecondaryColor: Color {
        Color.accentColor
    }

    private var symbolShadowColor: Color {
        colorScheme == .dark ? Color.accentColor.opacity(0.28) : Color.accentColor.opacity(0.18)
    }
}

#Preview {
    AnimatedSymbolSceneView(
        symbolNames: ["clock.badge.questionmark.fill", "drop.fill", "moon.zzz.fill"]
    )
    .padding()
}
