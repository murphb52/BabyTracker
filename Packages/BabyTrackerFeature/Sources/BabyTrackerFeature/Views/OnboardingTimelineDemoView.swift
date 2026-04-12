import SwiftUI

/// A scaled, clipped, non-interactive embed of `TimelineWeekView` using static demo data.
/// Used as the demo embed on the "See the whole picture" onboarding page.
struct OnboardingTimelineDemoView: View {
    private let naturalHeight: CGFloat = 380

    var body: some View {
        TimelineWeekView(
            columns: OnboardingDemoDataFactory.timelineStripColumns,
            selectedDay: .now,
            showDay: { _ in }
        )
        .frame(height: naturalHeight)
        .scaleEffect(0.75, anchor: .top)
        .frame(height: naturalHeight * 0.75)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .allowsHitTesting(false)
    }
}

#Preview {
    OnboardingTimelineDemoView()
        .padding(.horizontal, 24)
}
