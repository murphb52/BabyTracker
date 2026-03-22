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
                        ChildWorkspaceTabView(model: model, profile: profile)
                    } else {
                        ProgressView("Loading profile…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Baby Tracker")
        }
        // Reset the stack when the app moves between top-level flows so stale
        // detail screens do not remain visible above a new root route.
        .id(model.route)
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
        .safeAreaInset(edge: .bottom) {
            if let undoDeleteMessage = model.undoDeleteMessage {
                UndoBannerView(
                    message: undoDeleteMessage,
                    undoAction: model.undoLastDeletedEvent
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }
}

#Preview {
    AppRootView(container: .preview)
}
