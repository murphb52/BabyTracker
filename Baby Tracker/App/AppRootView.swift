import BabyTrackerFeature
import BabyTrackerLiveActivities
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
                if let shareAcceptanceLoadingState = model.shareAcceptanceLoadingState {
                    ShareAcceptanceLoadingView(state: shareAcceptanceLoadingState)
                        .toolbar(.hidden, for: .navigationBar)
                } else {
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
        }
        // Reset the stack when the app moves between top-level flows so stale
        // detail screens do not remain visible above a new root route.
        .id("\(String(describing: model.route))-\(model.navigationResetToken)")
        .overlay(alignment: .top) {
            ZStack(alignment: .topTrailing) {
                if let errorMessage = model.errorMessage {
                    ErrorBannerView(
                        message: errorMessage,
                        dismissAction: model.dismissError
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                if let syncBannerState = model.syncBannerState {
                    SyncIndicatorView(state: syncBannerState)
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity.combined(with: .move(edge: .bottom))
                            )
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .topTrailing)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: model.syncBannerState != nil)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await model.refreshSyncStatus() }
            }
        }
        .task {
            model.requestNotificationAuthorizationIfNeeded()
        }
        .onOpenURL { url in
            guard let childID = FeedLiveActivityDeepLink.endSleepChildID(from: url) else {
                return
            }

            model.selectChild(id: childID)
            model.requestSleepSheetPresentation()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if let transientMessage = model.transientMessage {
                    TransientMessageBannerView(message: transientMessage)
                        .padding(.horizontal, 16)
                }

                if let undoDeleteMessage = model.undoDeleteMessage {
                    UndoBannerView(
                        message: undoDeleteMessage,
                        undoAction: model.undoLastDeletedEvent
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    AppRootView(container: .preview)
}
