import SwiftUI

/// Animated page wrapper used by the three feature-demo steps (Quick Log, Timeline, Charts).
///
/// Title and body text stagger in on appear. The `demo` content is responsible for its
/// own entry animation so per-element timing is preserved. The page indicator dots are
/// rendered at the bottom.
struct OnboardingDemoPageContainer<Demo: View>: View {
    let title: String
    let message: String
    let pageIndex: Int
    let totalDemoPages: Int
    let demo: () -> Demo

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var titleAppeared = false
    @State private var messageAppeared = false

    init(
        title: String,
        message: String,
        pageIndex: Int,
        totalDemoPages: Int = 4,
        @ViewBuilder demo: @escaping () -> Demo
    ) {
        self.title = title
        self.message = message
        self.pageIndex = pageIndex
        self.totalDemoPages = totalDemoPages
        self.demo = demo
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(titleAppeared ? 1 : 0)
                    .offset(y: titleAppeared ? 0 : 18)

                Text(message)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(messageAppeared ? 1 : 0)
                    .offset(y: messageAppeared ? 0 : 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 20)

            demo()
                .padding(.horizontal, 24)

            pageIndicator
                .padding(.top, 20)
        }
        .onAppear {
            animateIn()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalDemoPages, id: \.self) { index in
                Capsule()
                    .fill(index == pageIndex ? Color.accentColor : Color.secondary.opacity(0.18))
                    .frame(width: index == pageIndex ? 28 : 10, height: 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding step \(pageIndex + 1) of \(totalDemoPages)")
    }

    private func animateIn() {
        if reduceMotion {
            titleAppeared = true
            messageAppeared = true
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            titleAppeared = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.09)) {
            messageAppeared = true
        }
    }
}

#Preview {
    OnboardingDemoPageContainer(
        title: "Log in seconds",
        message: "Tap one button, fill in the details, done. No fumbling around.",
        pageIndex: 1
    ) {
        Color.accentColor.opacity(0.1)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
