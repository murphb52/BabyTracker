import SwiftUI

/// A non-interactive embed of the real `ChildHomeView` shown after the user logs
/// their first event. Demonstrates what the app looks like with live data.
///
/// Title and subtitle stagger in first, then the app preview slides up with a
/// slight delay so the text has a moment to settle before the UI appears.
struct OnboardingAppPreviewStepView: View {
    let model: AppModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var homeViewModel: HomeViewModel
    @State private var childProfileViewModel: ChildProfileViewModel
    @State private var titleAppeared = false
    @State private var subtitleAppeared = false
    @State private var previewAppeared = false

    init(model: AppModel) {
        self.model = model
        _homeViewModel = State(initialValue: HomeViewModel(appModel: model))
        _childProfileViewModel = State(initialValue: ChildProfileViewModel(appModel: model))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Here's your app")
                    .font(.largeTitle.weight(.bold))
                    .opacity(titleAppeared ? 1 : 0)
                    .offset(y: titleAppeared ? 0 : 18)

                Text("Everything you just logged is already there.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(subtitleAppeared ? 1 : 0)
                    .offset(y: subtitleAppeared ? 0 : 14)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 16)

            ChildHomeView(
                model: model,
                viewModel: homeViewModel,
                childProfileViewModel: childProfileViewModel,
                stopSleep: {},
                quickLogBreastFeed: {},
                quickLogBottleFeed: {},
                quickLogSleep: {},
                quickLogNappy: {}
            )
            .allowsHitTesting(false)
            .opacity(previewAppeared ? 1 : 0)
            .offset(y: previewAppeared ? 0 : 24)
        }
        .onAppear {
            animateIn()
        }
    }

    private func animateIn() {
        if reduceMotion {
            titleAppeared = true
            subtitleAppeared = true
            previewAppeared = true
            return
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            titleAppeared = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.09)) {
            subtitleAppeared = true
        }
        withAnimation(.spring(response: 0.52, dampingFraction: 0.82).delay(0.22)) {
            previewAppeared = true
        }
    }
}

#Preview {
    OnboardingAppPreviewStepView(
        model: ChildProfilePreviewFactory.makeModel()
    )
}
