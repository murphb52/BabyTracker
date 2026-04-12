import BabyTrackerDomain
import SwiftUI

/// A demo of the Quick Log grid, used on the "Log in seconds" onboarding page.
///
/// Buttons stagger in on appear, then cycle a gentle spotlight highlight so
/// each event type gets a moment of attention.
struct OnboardingQuickLogDemoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appearedMask: [Bool] = [false, false, false, false]
    @State private var highlightedIndex = 0

    private let buttons: [(title: String, kind: BabyEventKind)] = [
        ("Breast Feed", .breastFeed),
        ("Bottle Feed", .bottleFeed),
        ("Start Sleep", .sleep),
        ("Nappy", .nappy),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Log")
                .font(.headline)
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    demoButton(index: 0)
                    demoButton(index: 1)
                }
                .geometryGroup()

                HStack(spacing: 12) {
                    demoButton(index: 2)
                    demoButton(index: 3)
                }
                .geometryGroup()
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            staggerIn()
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            // Wait for stagger to finish before cycling starts
            try? await Task.sleep(for: .milliseconds(900))
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.2))
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) {
                        highlightedIndex = (highlightedIndex + 1) % buttons.count
                    }
                }
            }
        }
    }

    private func demoButton(index: Int) -> some View {
        let entry = appearedMask[index]
        let isHighlighted = highlightedIndex == index && appearedMask.allSatisfy({ $0 })
        let item = buttons[index]

        return Label(item.title, systemImage: BabyEventStyle.systemImage(for: item.kind))
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .padding(.horizontal, 14)
            .foregroundStyle(BabyEventStyle.buttonForegroundColor(for: item.kind))
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(BabyEventStyle.buttonFillColor(for: item.kind))
                    .shadow(
                        color: BabyEventStyle.buttonFillColor(for: item.kind).opacity(isHighlighted ? 0.55 : 0),
                        radius: isHighlighted ? 10 : 0,
                        y: isHighlighted ? 4 : 0
                    )
            )
            .scaleEffect(isHighlighted ? 1.035 : 1.0)
            .opacity(entry ? 1 : 0)
            .offset(y: entry ? 0 : 18)
    }

    private func staggerIn() {
        if reduceMotion {
            appearedMask = [true, true, true, true]
            return
        }

        for index in 0..<buttons.count {
            let delay = Double(index) * 0.09
            withAnimation(.spring(response: 0.46, dampingFraction: 0.8).delay(delay)) {
                appearedMask[index] = true
            }
        }
    }
}

#Preview {
    OnboardingQuickLogDemoView()
        .frame(width: 360)
}
