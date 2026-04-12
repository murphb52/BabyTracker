import SwiftUI

/// A non-interactive embed of the real `ChildHomeView` shown after the user logs
/// their first event. Demonstrates what the app looks like with live data.
struct OnboardingAppPreviewStepView: View {
    let model: AppModel

    @State private var homeViewModel: HomeViewModel
    @State private var childProfileViewModel: ChildProfileViewModel

    init(model: AppModel) {
        self.model = model
        _homeViewModel = State(initialValue: HomeViewModel(appModel: model))
        _childProfileViewModel = State(initialValue: ChildProfileViewModel(appModel: model))
    }

    var body: some View {
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
    }
}

#Preview {
    OnboardingAppPreviewStepView(
        model: ChildProfilePreviewFactory.makeModel()
    )
}
