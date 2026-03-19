import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildProfileView: View {
    let model: AppModel
    let profile: ChildProfileScreenState

    @State private var showingEditChildSheet = false
    @State private var showingArchiveConfirmation = false
    @State private var activeFeedSheet: FeedSheet?
    @State private var deleteCandidate: RecentFeedEventViewState?

    var body: some View {
        @Bindable var bindableModel = model

        List {
            Section("Current Status") {
                CurrentStateCardView(summary: profile.currentStateSummary)
            }

            if profile.canLogFeeds {
                Section("Quick Log") {
                    quickLogButton(
                        title: "Breast Feed",
                        systemImage: "heart.text.square",
                        tint: .pink,
                        accessibilityIdentifier: "quick-log-breast-feed-button"
                    ) {
                        activeFeedSheet = .quickLogBreastFeed
                    }

                    quickLogButton(
                        title: "Bottle Feed",
                        systemImage: "drop.circle",
                        tint: .teal,
                        accessibilityIdentifier: "quick-log-bottle-feed-button"
                    ) {
                        activeFeedSheet = .quickLogBottleFeed
                    }
                }
            }

            Section("Recent Feeds") {
                if profile.recentFeedEvents.isEmpty {
                    Text(emptyFeedText)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("recent-feeds-empty-state")
                } else {
                    ForEach(profile.recentFeedEvents) { event in
                        recentFeedRow(for: event)
                    }
                }
            }

            if let syncBannerState = profile.syncBannerState {
                Section {
                    Label(syncBannerState.message, systemImage: syncBannerIcon(for: syncBannerState))
                        .font(.subheadline)
                        .foregroundStyle(syncBannerColor(for: syncBannerState))
                }
            }

            Section("Profile") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(profile.child.name)
                        .font(.title3.weight(.semibold))
                        .accessibilityIdentifier("child-profile-name")

                    Text(birthDateText)
                        .foregroundStyle(.secondary)

                    Text("Signed in as \(profile.localUser.displayName)")
                        .foregroundStyle(.secondary)
                }

                if profile.canSwitchChildren {
                    Button("Switch Child", systemImage: "arrow.left.arrow.right") {
                        model.showChildPicker()
                    }
                    .accessibilityIdentifier("switch-child-button")
                }
            }

            Section("Owner") {
                caregiverRow(for: profile.owner, showsRemoval: false)
            }

            if !profile.activeCaregivers.isEmpty {
                Section("Active Caregivers") {
                    ForEach(profile.activeCaregivers) { caregiver in
                        caregiverRow(
                            for: caregiver,
                            showsRemoval: profile.canManageSharing
                        )
                    }
                }
            }

            if !profile.pendingShareInvites.isEmpty {
                Section("Pending Invitations") {
                    ForEach(profile.pendingShareInvites) { invite in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(invite.displayName)
                                .font(.headline)

                            Text(invite.statusLabel)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !profile.removedCaregivers.isEmpty {
                Section("Removed Caregivers") {
                    ForEach(profile.removedCaregivers) { caregiver in
                        caregiverRow(for: caregiver, showsRemoval: false)
                    }
                }
            }

            if profile.canArchiveChild {
                Section {
                    Button("Archive Child", role: .destructive) {
                        showingArchiveConfirmation = true
                    }
                    .accessibilityIdentifier("archive-child-button")
                }
            }
        }
        .sheet(isPresented: $showingEditChildSheet) {
            ChildEditSheetView(
                initialName: profile.child.name,
                initialBirthDate: profile.child.birthDate,
                saveAction: model.updateCurrentChild(name:birthDate:)
            )
        }
        .sheet(item: $activeFeedSheet, onDismiss: {
            activeFeedSheet = nil
        }) { sheet in
            switch sheet {
            case .quickLogBreastFeed:
                BreastFeedEditorSheetView(
                    navigationTitle: "Breast Feed",
                    primaryActionTitle: "Save",
                    initialDurationMinutes: 15,
                    initialEndTime: Date(),
                    initialSide: nil
                ) { durationMinutes, endTime, side in
                    let didSave = model.logBreastFeed(
                        durationMinutes: durationMinutes,
                        endTime: endTime,
                        side: side
                    )
                    if didSave {
                        activeFeedSheet = nil
                    }
                    return didSave
                }
            case .quickLogBottleFeed:
                BottleFeedEditorSheetView(
                    navigationTitle: "Bottle Feed",
                    primaryActionTitle: "Save",
                    initialAmountMilliliters: 120,
                    initialOccurredAt: Date(),
                    initialMilkType: nil
                ) { amountMilliliters, occurredAt, milkType in
                    let didSave = model.logBottleFeed(
                        amountMilliliters: amountMilliliters,
                        occurredAt: occurredAt,
                        milkType: milkType
                    )
                    if didSave {
                        activeFeedSheet = nil
                    }
                    return didSave
                }
            case let .editRecentFeed(event):
                feedEditor(for: event)
            }
        }
        .sheet(item: $bindableModel.shareSheetState) { shareState in
            CloudKitShareSheetView(shareState: shareState, childName: profile.child.name)
                .onDisappear {
                    model.dismissShareSheet()
                    model.refreshAfterShareSheet()
                }
        }
        .confirmationDialog(
            archiveDialogTitle,
            isPresented: $showingArchiveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Archive Child", role: .destructive) {
                model.archiveCurrentChild()
            }
        } message: {
            Text("Archived child profiles are hidden from the main flow until restored.")
        }
        .confirmationDialog(
            "Delete Feed?",
            isPresented: deleteConfirmationIsPresented,
            titleVisibility: .visible,
            presenting: deleteCandidate
        ) { event in
            Button("Delete Feed", role: .destructive) {
                model.deleteEvent(id: event.id)
                deleteCandidate = nil
            }
        } message: { event in
            Text("Delete \(event.title.lowercased()) from \(event.timestampText)?")
        }
        .toolbar {
            if profile.canEditChild {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Edit Child") {
                        showingEditChildSheet = true
                    }
                    .accessibilityIdentifier("edit-child-button")
                }
            }

            if profile.canManageSharing {
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

    private var archiveDialogTitle: String {
        "Archive \(profile.child.name)?"
    }

    private var birthDateText: String {
        if let birthDate = profile.child.birthDate {
            "Birth date: \(birthDate.formatted(date: .abbreviated, time: .omitted))"
        } else {
            "Birth date not added yet"
        }
    }

    private var deleteConfirmationIsPresented: Binding<Bool> {
        Binding(
            get: { deleteCandidate != nil },
            set: { isPresented in
                if !isPresented {
                    deleteCandidate = nil
                }
            }
        )
    }

    private var emptyFeedText: String {
        "No feeds logged yet. Use Quick Log above to add the first feed."
    }

    private func quickLogButton(
        title: String,
        systemImage: String,
        tint: Color,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.white)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    @ViewBuilder
    private func recentFeedRow(for event: RecentFeedEventViewState) -> some View {
        let rowContent = HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)

                Text(event.detailText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(event.timestampText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)

        if profile.canManageFeedEvents {
            Button {
                activeFeedSheet = .editRecentFeed(event)
            } label: {
                rowContent
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("recent-feed-\(event.id.uuidString)")
            .simultaneousGesture(
                TapGesture().onEnded {
                    activeFeedSheet = .editRecentFeed(event)
                }
            )
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button("Edit") {
                    activeFeedSheet = .editRecentFeed(event)
                }
            }
            .swipeActions {
                Button("Delete", role: .destructive) {
                    deleteCandidate = event
                }
            }
        } else {
            rowContent
        }
    }

    @ViewBuilder
    private func caregiverRow(
        for caregiver: CaregiverMembershipViewState,
        showsRemoval: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(caregiver.displayName)
                    .font(.headline)

                Text(caregiver.statusLabel)
                    .font(.subheadline.weight(.medium))

                Text(caregiver.secondaryLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if showsRemoval {
                HStack {
                    if showsRemoval {
                        Button("Remove", role: .destructive) {
                            model.removeCaregiver(membershipID: caregiver.membership.id)
                        }
                        .accessibilityIdentifier("remove-caregiver-\(caregiver.membership.id.uuidString)")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func feedEditor(for event: RecentFeedEventViewState) -> some View {
        switch event.editPayload {
        case let .breastFeed(durationMinutes, endTime, side):
            BreastFeedEditorSheetView(
                navigationTitle: "Edit Breast Feed",
                primaryActionTitle: "Update",
                initialDurationMinutes: durationMinutes,
                initialEndTime: endTime,
                initialSide: side
            ) { updatedDuration, updatedEndTime, updatedSide in
                let didSave = model.updateBreastFeed(
                    id: event.id,
                    durationMinutes: updatedDuration,
                    endTime: updatedEndTime,
                    side: updatedSide
                )
                if didSave {
                    activeFeedSheet = nil
                }
                return didSave
            }
        case let .bottleFeed(amountMilliliters, occurredAt, milkType):
            BottleFeedEditorSheetView(
                navigationTitle: "Edit Bottle Feed",
                primaryActionTitle: "Update",
                initialAmountMilliliters: amountMilliliters,
                initialOccurredAt: occurredAt,
                initialMilkType: milkType
            ) { updatedAmount, updatedOccurredAt, updatedMilkType in
                let didSave = model.updateBottleFeed(
                    id: event.id,
                    amountMilliliters: updatedAmount,
                    occurredAt: updatedOccurredAt,
                    milkType: updatedMilkType
                )
                if didSave {
                    activeFeedSheet = nil
                }
                return didSave
            }
        }
    }

    private func syncBannerIcon(for state: SyncBannerState) -> String {
        switch state {
        case .syncing:
            "arrow.triangle.2.circlepath"
        case .pendingSync:
            "clock.badge.exclamationmark"
        case .syncUnavailable:
            "icloud.slash"
        case .lastSyncFailed:
            "exclamationmark.icloud"
        }
    }

    private func syncBannerColor(for state: SyncBannerState) -> Color {
        switch state {
        case .syncing:
            .blue
        case .pendingSync:
            .orange
        case .syncUnavailable, .lastSyncFailed:
            .red
        }
    }
}

extension ChildProfileView {
    private enum FeedSheet: Identifiable {
        case quickLogBreastFeed
        case quickLogBottleFeed
        case editRecentFeed(RecentFeedEventViewState)

        var id: String {
            switch self {
            case .quickLogBreastFeed:
                "quick-log-breast-feed"
            case .quickLogBottleFeed:
                "quick-log-bottle-feed"
            case let .editRecentFeed(event):
                "edit-\(event.id.uuidString)"
            }
        }
    }
}
