import BabyTrackerFeature
import SwiftUI

struct AppRootView: View {
    @State private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

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
                        .toolbar(.hidden, for: .navigationBar)
                case .identityOnboarding:
                    IdentityOnboardingView(model: model)
                        .toolbar(.hidden, for: .navigationBar)
                case .noChildren:
                    NoChildrenView(model: model)
                        .toolbar(.hidden, for: .navigationBar)
                case .childPicker:
                    ChildPickerView(model: model)
                        .navigationTitle("Baby Tracker")
                case .childProfile:
                    if let profile = model.profile {
                        ChildWorkspaceTabView(model: model, profile: profile)
                    } else {
                        ProgressView("Loading profile…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        // Reset the stack when the app moves between top-level flows so stale
        // detail screens do not remain visible above a new root route.
        .id(model.route)
        .overlay(alignment: .top) {
            if let errorMessage = model.errorMessage {
                ErrorBannerView(
                    message: errorMessage,
                    dismissAction: model.dismissError
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                model.refreshSyncStatus()
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
