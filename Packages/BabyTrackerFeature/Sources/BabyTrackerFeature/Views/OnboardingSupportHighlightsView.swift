import SwiftUI

struct OnboardingSupportHighlightsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleMask = [false, false, false]

    private let items: [Highlight] = [
        Highlight(
            title: "Log easily",
            message: "Capture feeds, sleeps, and nappies in a couple of taps.",
            symbolName: "hand.tap.fill",
            accentColor: .accentColor
        ),
        Highlight(
            title: "See patterns",
            message: "Spot rhythms over the day without piecing it together yourself.",
            symbolName: "chart.line.uptrend.xyaxis",
            accentColor: BabyEventStyle.accentColor(for: .sleep)
        ),
        Highlight(
            title: "Share together",
            message: "Keep your partner in the loop with one shared timeline.",
            symbolName: "person.2.fill",
            accentColor: BabyEventStyle.accentColor(for: .bottleFeed)
        ),
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.symbolName)
                        .font(.headline)
                        .foregroundStyle(item.accentColor)
                        .frame(width: 18, height: 18)
                        .padding(10)
                        .background(item.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))

                        Text(item.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .opacity(visibleMask[index] ? 1 : 0)
                .offset(y: visibleMask[index] ? 0 : 16)
            }
        }
        .onAppear {
            animateIn()
        }
    }

    private func animateIn() {
        guard !reduceMotion else {
            visibleMask = [true, true, true]
            return
        }

        Task { @MainActor in
            // Wait for the header title and message to finish animating in.
            try? await Task.sleep(for: .milliseconds(320))
            for index in items.indices {
                withAnimation(.spring(response: 0.48, dampingFraction: 0.78)) {
                    visibleMask[index] = true
                }
                guard index < items.count - 1 else { break }
                try? await Task.sleep(for: .milliseconds(120))
            }
        }
    }
}

private struct Highlight: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let symbolName: String
    let accentColor: Color
}

#Preview {
    OnboardingSupportHighlightsView()
        .padding()
}
