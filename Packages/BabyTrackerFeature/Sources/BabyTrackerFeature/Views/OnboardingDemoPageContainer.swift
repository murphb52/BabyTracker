import SwiftUI

/// Animated page wrapper used by the three feature-demo steps (Quick Log, Timeline, Charts).
///
/// Title and body text stagger in on appear. The `demo` content is responsible for its
/// own entry animation so per-element timing is preserved. The page indicator lives in
/// `InteractiveOnboardingView`'s footer so it stays pinned just above the Continue button
/// across all four intro pages.
struct OnboardingDemoPageContainer<Demo: View>: View {
    let title: String
    let message: String
    let demo: () -> Demo

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var titleAppeared = false
    @State private var messageAppeared = false

    init(
        title: String,
        message: String,
        @ViewBuilder demo: @escaping () -> Demo
    ) {
        self.title = title
        self.message = message
        self.demo = demo
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(titleAppeared ? 1 : 0)

                Text(message)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(messageAppeared ? 1 : 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 20)

            demo()
                .padding(.horizontal, 24)
        }
        .onAppear {
            animateIn()
        }
    }

    private func animateIn() {
        if reduceMotion {
            titleAppeared = true
            messageAppeared = true
            return
        }

        withAnimation(.easeIn(duration: 0.35)) {
            titleAppeared = true
        }
        withAnimation(.easeIn(duration: 0.35).delay(0.1)) {
            messageAppeared = true
        }
    }
}

#Preview {
    OnboardingDemoPageContainer(
        title: "Log anything in 2 taps",
        message: "Tap one button, fill in the details, done. No fumbling around."
    ) {
        Color.accentColor.opacity(0.1)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
