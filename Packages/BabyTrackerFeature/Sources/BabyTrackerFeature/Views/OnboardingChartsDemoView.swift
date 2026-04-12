import SwiftUI

/// A scaled, clipped demo of `SummaryScreenView` used on the "Spot the patterns"
/// onboarding page.
///
/// Slides up and fades in on appear. The Charts framework animates its own content
/// on first render, providing natural visual interest without extra animation overhead.
struct OnboardingChartsDemoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = OnboardingDemoDataFactory.summaryViewModel

    @State private var appeared = false

    private let naturalHeight: CGFloat = 560

    var body: some View {
        SummaryScreenView(viewModel: viewModel)
            .frame(height: naturalHeight)
            .scaleEffect(0.72, anchor: .top)
            .frame(height: naturalHeight * 0.72)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .allowsHitTesting(false)
            // Entry slide-up
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 28)
            .animation(
                reduceMotion ? nil : .spring(response: 0.52, dampingFraction: 0.82).delay(0.15),
                value: appeared
            )
            .onAppear {
                appeared = true
            }
    }
}

#Preview {
    OnboardingChartsDemoView()
        .padding(.horizontal, 24)
}
