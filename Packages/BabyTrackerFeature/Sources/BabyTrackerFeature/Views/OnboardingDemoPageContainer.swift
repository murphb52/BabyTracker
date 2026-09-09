import SwiftUI

/// Animated page wrapper used by feature-demo steps.
///
/// Title and body text stagger in on appear. The `demo` content is responsible for its
/// own entry animation so per-element timing is preserved. The page indicator lives in
/// `InteractiveOnboardingView`'s footer so it stays pinned just above the Continue button
/// across all intro pages.
struct OnboardingDemoPageContainer<Demo: View>: View {
    let title: String
    let message: String
    let characterScene: OnboardingCharacterScene
    let demo: () -> Demo

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var titleAppeared = false
    @State private var messageAppeared = false

    init(
        title: String,
        message: String,
        characterScene: OnboardingCharacterScene,
        @ViewBuilder demo: @escaping () -> Demo
    ) {
        self.title = title
        self.message = message
        self.characterScene = characterScene
        self.demo = demo
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    OnboardingCharacterSceneView(scene: characterScene)

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
                    .frame(minHeight: 132, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 20)

                demo()
                    .padding(.horizontal, 24)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
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
        message: "Tap one button, fill in the details, done. No fumbling around.",
        characterScene: .quickLog
    ) {
        Color.accentColor.opacity(0.1)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
