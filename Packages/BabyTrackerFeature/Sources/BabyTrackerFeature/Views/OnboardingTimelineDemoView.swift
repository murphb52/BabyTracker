import SwiftUI

/// A scaled, clipped demo of `TimelineWeekView` used on the "See the whole picture"
/// onboarding page.
///
/// Slides up and fades in on appear, then breathes gently on a slow loop to suggest
/// the timeline is alive and filling in.
struct OnboardingTimelineDemoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false
    @State private var breathing = false

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
        // Gentle breathing after entry
        .scaleEffect(breathing ? 1.012 : 1.0, anchor: .bottom)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 3.8).repeatForever(autoreverses: true),
            value: breathing
        )
        // Entry slide-up
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .animation(
            reduceMotion ? nil : .spring(response: 0.52, dampingFraction: 0.82).delay(0.15),
            value: appeared
        )
        .onAppear {
            if reduceMotion {
                appeared = true
                return
            }
            appeared = true
            // Start breathing after the entry settles
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(700))
                breathing = true
            }
        }
    }
}

#Preview {
    OnboardingTimelineDemoView()
        .padding(.horizontal, 24)
}
