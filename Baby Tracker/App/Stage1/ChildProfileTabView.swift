import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildProfileTabView: View {
    let model: AppModel
    let profile: ChildProfileScreenState

    @State private var selectedTab: Tab = .profile
    @State private var showingEditChildSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ChildProfileView(model: model, profile: profile)
                .tag(Tab.profile)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }

            TimelineScreenView(model: model)
                .tag(Tab.timeline)
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }
        }
        .sheet(isPresented: $showingEditChildSheet) {
            ChildEditSheetView(
                initialName: profile.child.name,
                initialBirthDate: profile.child.birthDate,
                saveAction: model.updateCurrentChild(name:birthDate:)
            )
        }
        .toolbar {
            if selectedTab == .profile && profile.canEditChild {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Edit Child") {
                        showingEditChildSheet = true
                    }
                    .accessibilityIdentifier("edit-child-button")
                }
            }

            if selectedTab == .profile && profile.canManageSharing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share", systemImage: "square.and.arrow.up") {
                        model.presentShareSheet()
                    }
                    .disabled(!profile.canShareChild)
                    .accessibilityIdentifier("share-child-button")
                }
            }
        }
    }
}

extension ChildProfileTabView {
    enum Tab: Hashable {
        case profile
        case timeline
    }
}
