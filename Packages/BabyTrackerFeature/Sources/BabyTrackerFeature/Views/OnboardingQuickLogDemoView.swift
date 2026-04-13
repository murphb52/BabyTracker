import BabyTrackerDomain
import SwiftUI

/// A demo of the Quick Log grid, used on the "Log in seconds" onboarding page.
///
/// Buttons pop in one by one on appear. Each button then cycles through a
/// zoom-up → wiggle → zoom-down animation when it becomes the active spotlight.
struct OnboardingQuickLogDemoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var cardVisible = false
    @State private var appearedMask: [Bool] = [false, false, false, false]
    @State private var highlightedIndex = 0
    @State private var wiggleScales: [Double] = [1.0, 1.0, 1.0, 1.0]
    @State private var rotations: [Double] = [0, 0, 0, 0]

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
        .opacity(cardVisible ? 1 : 0)
        .offset(y: cardVisible ? 0 : 20)
        .animation(
            reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8),
            value: cardVisible
        )
        .onAppear {
            if reduceMotion {
                cardVisible = true
                appearedMask = [true, true, true, true]
                return
            }
            Task { @MainActor in
                // Delay until the page slide-in transition has settled (~420ms spring)
                try? await Task.sleep(for: .milliseconds(420))
                cardVisible = true
                // Let the card spring land before the buttons start popping in.
                try? await Task.sleep(for: .milliseconds(520))
                staggerIn()
            }
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            // Wait for slide-in, card spring, and full stagger to finish before first wiggle.
            try? await Task.sleep(for: .milliseconds(1870))
            // Animate the initial highlighted button
            animateWiggle(0)
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.4))
                guard !Task.isCancelled else { break }
                let next = (highlightedIndex + 1) % buttons.count
                withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) {
                    highlightedIndex = next
                }
                animateWiggle(next)
            }
        }
    }

    private func demoButton(index: Int) -> some View {
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
            .scaleEffect(wiggleScales[index])
            .rotationEffect(.degrees(rotations[index]))
            .opacity(appearedMask[index] ? 1 : 0)
            .offset(y: appearedMask[index] ? 0 : 22)
    }

    private func staggerIn() {
        for index in 0..<buttons.count {
            let delay = Double(index) * 0.1
            withAnimation(.spring(response: 0.38, dampingFraction: 0.52).delay(delay)) {
                appearedMask[index] = true
            }
        }
    }

    /// Plays a zoom-up → wiggle → zoom-down sequence on the button at `index`.
    private func animateWiggle(_ index: Int) {
        guard !reduceMotion else { return }
        // 1. Zoom up slightly
        withAnimation(.spring(response: 0.22, dampingFraction: 0.6)) {
            wiggleScales[index] = 1.06
        }
        Task { @MainActor in
            // 2. Short pause so zoom lands before wiggle starts
            try? await Task.sleep(for: .milliseconds(160))
            // 3. Gentle wiggle sequence
            let rotationSteps: [Double] = [4, -4, 3, 0]
            for rot in rotationSteps {
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.14, dampingFraction: 0.6)) {
                    rotations[index] = rot
                }
                try? await Task.sleep(for: .milliseconds(110))
            }
            // 4. Zoom back to normal
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                wiggleScales[index] = 1.0
            }
        }
    }
}

#Preview {
    OnboardingQuickLogDemoView()
        .frame(width: 360)
}
