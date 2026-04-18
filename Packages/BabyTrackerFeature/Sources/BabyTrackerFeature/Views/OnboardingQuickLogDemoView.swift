import BabyTrackerDomain
import SwiftUI

/// A demo of the Quick Log grid, used on the "Log anything in 2 taps" onboarding page.
///
/// Buttons pop in one by one on appear after the full card settles into place.
struct OnboardingQuickLogDemoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var cardVisible = false
    @State private var appearedMask: [Bool] = [false, false, false, false]

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

                HStack(spacing: 12) {
                    demoButton(index: 2)
                    demoButton(index: 3)
                }
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
    }

    private func demoButton(index: Int) -> some View {
        let item = buttons[index]

        return ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BabyEventStyle.buttonFillColor(for: item.kind))

            HStack(spacing: 8) {
                Image(systemName: BabyEventStyle.systemImage(for: item.kind))
                    .font(.footnote.weight(.semibold))

                Text(item.title)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)
            }
            .foregroundStyle(BabyEventStyle.buttonForegroundColor(for: item.kind))
            .padding(.horizontal, 14)
        }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .drawingGroup()
            .opacity(appearedMask[index] ? 1 : 0)
            .offset(y: appearedMask[index] ? 0 : 18)
            .scaleEffect(appearedMask[index] ? 1 : 0.94)
    }

    private func staggerIn() {
        Task { @MainActor in
            for index in 0..<buttons.count {
                withAnimation(.spring(response: 0.52, dampingFraction: 0.74)) {
                    appearedMask[index] = true
                }

                guard index < buttons.count - 1 else { break }
                try? await Task.sleep(for: .milliseconds(150))
            }
        }
    }
}

#Preview {
    OnboardingQuickLogDemoView()
        .frame(width: 360)
}
