import BabyTrackerFeature
import SwiftUI

struct AppRootView: View {
    @State private var model: AppModel

    init(container: AppContainer) {
        _model = State(initialValue: container.appModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch model.route {
                case .loading:
                    ProgressView("Loading profile…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .identityOnboarding:
                    IdentityOnboardingView(model: model)
                case .childCreation:
                    ChildCreationView(model: model)
                case .childPicker:
                    ChildPickerView(model: model)
                case .childProfile:
                    if let profile = model.profile {
                        ChildProfileView(model: model, profile: profile)
                    } else {
                        ProgressView("Loading profile…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Baby Tracker")
        }
        .overlay(alignment: .top) {
            if let errorMessage = model.errorMessage {
                Stage1ErrorBannerView(
                    message: errorMessage,
                    dismissAction: model.dismissError
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
}

#Preview {
    AppRootView(container: .preview)
}
