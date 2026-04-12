import SwiftUI

/// A scaled, clipped demo of `SummaryScreenView` used on the "Spot the patterns"
/// onboarding page.
///
/// Slides up and fades in on appear. `SummaryScreenView` is inserted into the hierarchy
/// only after the entry animation settles so the Charts framework fires its built-in
/// line-draw and bar-grow animations while the demo is fully visible.
struct OnboardingChartsDemoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false
    @State private var showCharts = false

    private let naturalHeight: CGFloat = 560

    var body: some View {
        ZStack {
            if showCharts {
                SummaryScreenView(viewModel: OnboardingDemoDataFactory.summaryViewModel)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .frame(height: naturalHeight)
        .scaleEffect(0.72, anchor: .top)
        .frame(height: naturalHeight * 0.72)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        // Entry slide-up
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 28)
        .animation(
            reduceMotion ? nil : .spring(response: 0.52, dampingFraction: 0.82).delay(0.15),
            value: appeared
        )
        .onAppear {
            appeared = true
            guard !reduceMotion else {
                showCharts = true
                return
            }
            // Insert SummaryScreenView after the entry slide settles so Charts
            // fires its line-draw and bar-grow animations while visible.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation(.easeIn(duration: 0.25)) {
                    showCharts = true
                }
            }
        }
    }
}

#Preview {
    OnboardingChartsDemoView()
        .padding(.horizontal, 24)
}
