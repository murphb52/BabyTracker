import SwiftUI

/// A scaled, clipped, non-interactive embed of `SummaryScreenView` using static preview data.
/// Used as the demo embed on the "Spot the patterns" onboarding page.
struct OnboardingChartsDemoView: View {
    @State private var viewModel = OnboardingDemoDataFactory.summaryViewModel
    private let naturalHeight: CGFloat = 560

    var body: some View {
        SummaryScreenView(viewModel: viewModel)
            .frame(height: naturalHeight)
            .scaleEffect(0.72, anchor: .top)
            .frame(height: naturalHeight * 0.72)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .allowsHitTesting(false)
    }
}

#Preview {
    OnboardingChartsDemoView()
        .padding(.horizontal, 24)
}
