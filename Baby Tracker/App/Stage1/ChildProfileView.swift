import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildProfileView: View {
    let model: AppModel
    let profile: ChildProfileScreenState

    @State private var showingArchiveConfirmation = false
    @State private var showingQuickLogNappyTypeDialog = false
    @State private var activeEventSheet: EventSheet?
    @State private var deleteCandidate: DeleteCandidate?

    var body: some View {
        @Bindable var bindableModel = model

        List {
            Section("Current Status") {
                CurrentStateCardView(summary: profile.currentStateSummary)
            }

            if profile.canLogEvents {
                Section("Quick Log") {
                    quickLogButton(
                        title: "Breast Feed",
                        systemImage: "heart.text.square",
                        tint: .pink,
                        accessibilityIdentifier: "quick-log-breast-feed-button"
                    ) {
                        activeEventSheet = .quickLogBreastFeed
                    }

                    quickLogButton(
                        title: "Bottle Feed",
                        systemImage: "drop.circle",
                        tint: .teal,
                        accessibilityIdentifier: "quick-log-bottle-feed-button"
                    ) {
                        activeEventSheet = .quickLogBottleFeed
                    }

                    quickLogButton(
                        title: sleepQuickLogTitle,
                        systemImage: "bed.double",
                        tint: .indigo,
                        accessibilityIdentifier: "quick-log-sleep-button"
                    ) {
                        if let activeSleepSession = profile.activeSleepSession {
                            activeEventSheet = .endSleep(activeSleepSession)
                        } else {
                            activeEventSheet = .startSleep
                        }
                    }

                    quickLogButton(
                        title: "Nappy",
                        systemImage: "checklist",
                        tint: .orange,
                        accessibilityIdentifier: "quick-log-nappy-button"
                    ) {
                        showingQuickLogNappyTypeDialog = true
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

            Section("Recent Sleep") {
                if profile.recentSleepEvents.isEmpty {
                    Text(emptySleepText)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("recent-sleep-empty-state")
                } else {
                    ForEach(profile.recentSleepEvents) { event in
                        recentSleepRow(for: event)
                    }
                }
            }

            Section("Recent Nappies") {
                if profile.recentNappyEvents.isEmpty {
                    Text(emptyNappyText)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("recent-nappies-empty-state")
                } else {
                    ForEach(profile.recentNappyEvents) { event in
                        recentNappyRow(for: event)
                    }
                }
            }

            Section("iCloud Sync") {
                LabeledContent("Status") {
                    Text(profile.cloudKitStatus.statusTitle)
                        .foregroundStyle(syncStatusColor(for: profile.cloudKitStatus))
                }

                LabeledContent("Backup") {
                    Text(profile.cloudKitStatus.backupTitle)
                }

                if let lastSyncAt = profile.cloudKitStatus.lastSyncAt {
                    LabeledContent("Last Sync") {
                        Text(lastSyncAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    }
                }

                if let pendingChangesTitle = profile.cloudKitStatus.pendingChangesTitle {
                    LabeledContent("Pending Changes") {
                        Text(pendingChangesTitle)
                    }
                }

                if let detailMessage = profile.cloudKitStatus.detailMessage {
                    Text(detailMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
        .navigationTitle(profile.child.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeEventSheet, onDismiss: {
            activeEventSheet = nil
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
                        activeEventSheet = nil
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
                        activeEventSheet = nil
                    }
                    return didSave
                }
            case .startSleep:
                SleepEditorSheetView(
                    mode: .start,
                    initialStartedAt: Date(),
                    initialEndedAt: nil
                ) { startedAt, _ in
                    let didSave = model.startSleep(startedAt: startedAt)
                    if didSave {
                        activeEventSheet = nil
                    }
                    return didSave
                }
            case let .endSleep(event):
                SleepEditorSheetView(
                    mode: .end,
                    initialStartedAt: event.startedAt,
                    initialEndedAt: defaultSleepEndTime(for: event.startedAt),
                    saveAction: { startedAt, endedAt in
                        guard let endedAt else {
                            return false
                        }

                        let didSave = model.endSleep(
                            id: event.id,
                            startedAt: startedAt,
                            endedAt: endedAt
                        )
                        if didSave {
                            activeEventSheet = nil
                        }
                        return didSave
                    },
                    deleteAction: profile.canManageEvents ? {
                        if model.deleteEvent(id: event.id) {
                            activeEventSheet = nil
                        }
                    } : nil
                )
            case let .quickLogNappy(type):
                NappyEditorSheetView(
                    navigationTitle: "Nappy",
                    primaryActionTitle: "Save",
                    initialType: type,
                    initialOccurredAt: Date(),
                    initialIntensity: nil,
                    initialPooColor: nil
                ) { updatedType, occurredAt, intensity, pooColor in
                    let didSave = model.logNappy(
                        type: updatedType,
                        occurredAt: occurredAt,
                        intensity: intensity,
                        pooColor: pooColor
                    )
                    if didSave {
                        activeEventSheet = nil
                    }
                    return didSave
                }
            case let .editBreastFeed(id, durationMinutes, endTime, side):
                BreastFeedEditorSheetView(
                    navigationTitle: "Edit Breast Feed",
                    primaryActionTitle: "Update",
                    initialDurationMinutes: durationMinutes,
                    initialEndTime: endTime,
                    initialSide: side
                ) { updatedDuration, updatedEndTime, updatedSide in
                    let didSave = model.updateBreastFeed(
                        id: id,
                        durationMinutes: updatedDuration,
                        endTime: updatedEndTime,
                        side: updatedSide
                    )
                    if didSave {
                        activeEventSheet = nil
                    }
                    return didSave
                }
            case let .editBottleFeed(id, amountMilliliters, occurredAt, milkType):
                BottleFeedEditorSheetView(
                    navigationTitle: "Edit Bottle Feed",
                    primaryActionTitle: "Update",
                    initialAmountMilliliters: amountMilliliters,
                    initialOccurredAt: occurredAt,
                    initialMilkType: milkType
                ) { updatedAmount, updatedOccurredAt, updatedMilkType in
                    let didSave = model.updateBottleFeed(
                        id: id,
                        amountMilliliters: updatedAmount,
                        occurredAt: updatedOccurredAt,
                        milkType: updatedMilkType
                    )
                    if didSave {
                        activeEventSheet = nil
                    }
                    return didSave
                }
            case let .editSleep(id, startedAt, endedAt):
                SleepEditorSheetView(
                    mode: .edit,
                    initialStartedAt: startedAt,
                    initialEndedAt: endedAt
                ) { updatedStartedAt, updatedEndedAt in
                    guard let updatedEndedAt else {
                        return false
                    }

                    let didSave = model.updateSleep(
                        id: id,
                        startedAt: updatedStartedAt,
                        endedAt: updatedEndedAt
                    )
                    if didSave {
                        activeEventSheet = nil
                    }
                    return didSave
                }
            case let .editNappy(id, type, occurredAt, intensity, pooColor):
                NappyEditorSheetView(
                    navigationTitle: "Edit Nappy",
                    primaryActionTitle: "Update",
                    initialType: type,
                    initialOccurredAt: occurredAt,
                    initialIntensity: intensity,
                    initialPooColor: pooColor
                ) { updatedType, updatedOccurredAt, updatedIntensity, updatedPooColor in
                    let didSave = model.updateNappy(
                        id: id,
                        type: updatedType,
                        occurredAt: updatedOccurredAt,
                        intensity: updatedIntensity,
                        pooColor: updatedPooColor
                    )
                    if didSave {
                        activeEventSheet = nil
                    }
                    return didSave
                }
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
            "Log Nappy",
            isPresented: $showingQuickLogNappyTypeDialog,
            titleVisibility: .visible
        ) {
            ForEach(NappyType.allCases, id: \.self) { type in
                Button(nappyTypeTitle(for: type)) {
                    activeEventSheet = .quickLogNappy(type)
                }
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
            deleteCandidate?.dialogTitle ?? "Delete Event?",
            isPresented: deleteConfirmationIsPresented,
            titleVisibility: .visible,
            presenting: deleteCandidate
        ) { event in
            Button(event.confirmButtonTitle, role: .destructive) {
                model.deleteEvent(id: event.id)
                deleteCandidate = nil
            }
        } message: { event in
            Text("Delete \(event.title.lowercased()) from \(event.timestampText)?")
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

    private var emptySleepText: String {
        "No sleep sessions logged yet. Use Quick Log above to add the first sleep."
    }

    private var emptyNappyText: String {
        "No nappies logged yet. Use Quick Log above to add the first nappy."
    }

    private var sleepQuickLogTitle: String {
        profile.activeSleepSession == nil ? "Start Sleep" : "End Sleep"
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
        let rowContent = eventRowContent(
            title: event.title,
            detailText: event.detailText,
            timestampText: event.timestampText
        )

        if profile.canManageEvents {
            Button {
                activeEventSheet = editSheet(for: event)
            } label: {
                rowContent
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("recent-feed-\(event.id.uuidString)")
            .simultaneousGesture(
                TapGesture().onEnded {
                    activeEventSheet = editSheet(for: event)
                }
            )
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button("Edit") {
                    activeEventSheet = editSheet(for: event)
                }
            }
            .swipeActions {
                Button("Delete", role: .destructive) {
                    deleteCandidate = deleteCandidate(for: event)
                }
            }
        } else {
            rowContent
        }
    }

    @ViewBuilder
    private func recentNappyRow(for event: RecentNappyEventViewState) -> some View {
        let rowContent = eventRowContent(
            title: event.title,
            detailText: event.detailText,
            timestampText: event.timestampText
        )

        if profile.canManageEvents {
            Button {
                activeEventSheet = editSheet(for: event)
            } label: {
                rowContent
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("recent-nappy-\(event.id.uuidString)")
            .simultaneousGesture(
                TapGesture().onEnded {
                    activeEventSheet = editSheet(for: event)
                }
            )
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button("Edit") {
                    activeEventSheet = editSheet(for: event)
                }
            }
            .swipeActions {
                Button("Delete", role: .destructive) {
                    deleteCandidate = deleteCandidate(for: event)
                }
            }
        } else {
            rowContent
        }
    }

    @ViewBuilder
    private func recentSleepRow(for event: RecentSleepEventViewState) -> some View {
        let rowContent = eventRowContent(
            title: event.title,
            detailText: event.detailText,
            timestampText: event.timestampText
        )

        if profile.canManageEvents {
            Button {
                activeEventSheet = editSheet(for: event)
            } label: {
                rowContent
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("recent-sleep-\(event.id.uuidString)")
            .simultaneousGesture(
                TapGesture().onEnded {
                    activeEventSheet = editSheet(for: event)
                }
            )
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button("Edit") {
                    activeEventSheet = editSheet(for: event)
                }
            }
            .swipeActions {
                Button("Delete", role: .destructive) {
                    deleteCandidate = deleteCandidate(for: event)
                }
            }
        } else {
            rowContent
        }
    }

    private func eventRowContent(
        title: String,
        detailText: String,
        timestampText: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(detailText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(timestampText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
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

    private func editSheet(
        for event: RecentFeedEventViewState
    ) -> EventSheet {
        switch event.editPayload {
        case let .breastFeed(durationMinutes, endTime, side):
            return .editBreastFeed(
                id: event.id,
                durationMinutes: durationMinutes,
                endTime: endTime,
                side: side
            )
        case let .bottleFeed(amountMilliliters, occurredAt, milkType):
            return .editBottleFeed(
                id: event.id,
                amountMilliliters: amountMilliliters,
                occurredAt: occurredAt,
                milkType: milkType
            )
        }
    }

    private func editSheet(
        for event: RecentNappyEventViewState
    ) -> EventSheet {
        .editNappy(
            id: event.id,
            type: event.editPayload.type,
            occurredAt: event.editPayload.occurredAt,
            intensity: event.editPayload.intensity,
            pooColor: event.editPayload.pooColor
        )
    }

    private func editSheet(
        for event: RecentSleepEventViewState
    ) -> EventSheet {
        .editSleep(
            id: event.id,
            startedAt: event.editPayload.startedAt,
            endedAt: event.editPayload.endedAt
        )
    }

    private func deleteCandidate(
        for event: RecentFeedEventViewState
    ) -> DeleteCandidate {
        DeleteCandidate(
            id: event.id,
            title: event.title,
            timestampText: event.timestampText,
            dialogTitle: "Delete Feed?",
            confirmButtonTitle: "Delete Feed"
        )
    }

    private func deleteCandidate(
        for event: RecentSleepEventViewState
    ) -> DeleteCandidate {
        DeleteCandidate(
            id: event.id,
            title: event.title,
            timestampText: event.timestampText,
            dialogTitle: "Delete Sleep?",
            confirmButtonTitle: "Delete Sleep"
        )
    }

    private func deleteCandidate(
        for event: RecentNappyEventViewState
    ) -> DeleteCandidate {
        DeleteCandidate(
            id: event.id,
            title: event.title,
            timestampText: event.timestampText,
            dialogTitle: "Delete Nappy?",
            confirmButtonTitle: "Delete Nappy"
        )
    }

    private func defaultSleepEndTime(for startedAt: Date) -> Date {
        let now = Date()

        if startedAt > now {
            return now
        }

        return max(now, startedAt.addingTimeInterval(60))
    }

    private func nappyTypeTitle(for type: NappyType) -> String {
        switch type {
        case .dry:
            "Dry"
        case .wee:
            "Wee"
        case .poo:
            "Poo"
        case .mixed:
            "Mixed"
        }
    }

    private func syncStatusColor(for state: CloudKitStatusViewState) -> Color {
        switch state.state {
        case .upToDate:
            .green
        case .syncing:
            .blue
        case .pendingSync:
            .orange
        case .failed:
            .red
        }
    }
}

extension ChildProfileView {
    private enum EventSheet: Identifiable {
        case quickLogBreastFeed
        case quickLogBottleFeed
        case startSleep
        case endSleep(ActiveSleepSessionViewState)
        case quickLogNappy(NappyType)
        case editBreastFeed(
            id: UUID,
            durationMinutes: Int,
            endTime: Date,
            side: BreastSide?
        )
        case editBottleFeed(
            id: UUID,
            amountMilliliters: Int,
            occurredAt: Date,
            milkType: MilkType?
        )
        case editSleep(
            id: UUID,
            startedAt: Date,
            endedAt: Date
        )
        case editNappy(
            id: UUID,
            type: NappyType,
            occurredAt: Date,
            intensity: NappyIntensity?,
            pooColor: PooColor?
        )

        var id: String {
            switch self {
            case .quickLogBreastFeed:
                "quick-log-breast-feed"
            case .quickLogBottleFeed:
                "quick-log-bottle-feed"
            case .startSleep:
                "start-sleep"
            case let .endSleep(event):
                "end-sleep-\(event.id.uuidString)"
            case let .quickLogNappy(type):
                "quick-log-nappy-\(type.rawValue)"
            case let .editBreastFeed(id, _, _, _):
                "edit-breast-feed-\(id.uuidString)"
            case let .editBottleFeed(id, _, _, _):
                "edit-bottle-feed-\(id.uuidString)"
            case let .editSleep(id, _, _):
                "edit-sleep-\(id.uuidString)"
            case let .editNappy(id, _, _, _, _):
                "edit-nappy-\(id.uuidString)"
            }
        }
    }

    private struct DeleteCandidate: Identifiable {
        let id: UUID
        let title: String
        let timestampText: String
        let dialogTitle: String
        let confirmButtonTitle: String
    }
}
