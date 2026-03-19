import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildProfileView: View {
    let model: AppModel
    let profile: ChildProfileScreenState

    @State private var showingEditChildSheet = false
    @State private var showingArchiveConfirmation = false
    @State private var quickLogSheet: FeedQuickLogSheet?

    var body: some View {
        @Bindable var bindableModel = model

        List {
            if profile.canLogFeeds {
                Section("Quick Log") {
                    quickLogButton(
                        title: "Breast Feed",
                        systemImage: "heart.text.square",
                        tint: .pink,
                        accessibilityIdentifier: "quick-log-breast-feed-button"
                    ) {
                        quickLogSheet = .breastFeed
                    }

                    quickLogButton(
                        title: "Bottle Feed",
                        systemImage: "drop.circle",
                        tint: .teal,
                        accessibilityIdentifier: "quick-log-bottle-feed-button"
                    ) {
                        quickLogSheet = .bottleFeed
                    }
                }
            }

            Section("Feeding") {
                if let feedingSummary = profile.feedingSummary {
                    summaryRow(
                        title: "Latest Feed",
                        value: feedingSummary.lastFeedTitle,
                        accessibilityIdentifier: "feeding-latest-feed-value"
                    )
                    summaryRow(
                        title: "Last Logged",
                        value: feedingSummary.lastFeedTimestamp,
                        accessibilityIdentifier: "feeding-last-logged-value"
                    )
                    summaryRow(
                        title: "Feeds Today",
                        value: feedingSummary.feedsTodayText,
                        accessibilityIdentifier: "feeding-count-value"
                    )
                } else {
                    Text("No feeds logged yet.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("feeding-empty-state")
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
        .sheet(item: $quickLogSheet) { sheet in
            switch sheet {
            case .breastFeed:
                BreastFeedQuickLogSheetView { durationMinutes, endTime, side in
                    model.logBreastFeed(
                        durationMinutes: durationMinutes,
                        endTime: endTime,
                        side: side
                    )
                }
            case .bottleFeed:
                BottleFeedQuickLogSheetView { amountMilliliters, occurredAt, milkType in
                    model.logBottleFeed(
                        amountMilliliters: amountMilliliters,
                        occurredAt: occurredAt,
                        milkType: milkType
                    )
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
            "Archive \(profile.child.name)?",
            isPresented: $showingArchiveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Archive Child", role: .destructive) {
                model.archiveCurrentChild()
            }
        } message: {
            Text("Archived child profiles are hidden from the main flow until restored.")
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

    private var birthDateText: String {
        if let birthDate = profile.child.birthDate {
            "Birth date: \(birthDate.formatted(date: .abbreviated, time: .omitted))"
        } else {
            "Birth date not added yet"
        }
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

    private func summaryRow(
        title: String,
        value: String,
        accessibilityIdentifier: String
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(accessibilityIdentifier)
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
    private enum FeedQuickLogSheet: String, Identifiable {
        case breastFeed
        case bottleFeed

        var id: String {
            rawValue
        }
    }

    private struct BreastFeedQuickLogSheetView: View {
        let saveAction: (_ durationMinutes: Int, _ endTime: Date, _ side: BreastSide?) -> Bool

        @Environment(\.dismiss) private var dismiss
        @State private var durationMinutes = "15"
        @State private var endTime = Date()
        @State private var side = BreastSideChoice.notSet

        var body: some View {
            NavigationStack {
                Form {
                    Section("Feed") {
                        TextField("Duration (minutes)", text: $durationMinutes)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("breast-feed-duration-field")

                        DatePicker(
                            "End time",
                            selection: $endTime,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .accessibilityIdentifier("breast-feed-end-time-picker")

                        Picker("Side", selection: $side) {
                            ForEach(BreastSideChoice.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .accessibilityIdentifier("breast-feed-side-picker")
                    }

                    if let validationMessage {
                        Section {
                            Text(validationMessage)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .navigationTitle("Breast Feed")
                .navigationBarTitleDisplayMode(.inline)
                .presentationDetents([.medium])
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            guard let durationValue = parsedDurationMinutes else {
                                return
                            }

                            let didSave = saveAction(durationValue, endTime, side.value)
                            if didSave {
                                dismiss()
                            }
                        }
                        .disabled(parsedDurationMinutes == nil)
                        .accessibilityIdentifier("save-breast-feed-button")
                    }
                }
            }
        }

        private var parsedDurationMinutes: Int? {
            guard let durationValue = Int(durationMinutes.trimmingCharacters(in: .whitespacesAndNewlines)),
                  durationValue > 0 else {
                return nil
            }

            return durationValue
        }

        private var validationMessage: String? {
            guard !durationMinutes.isEmpty, parsedDurationMinutes == nil else {
                return nil
            }

            return "Enter a duration greater than 0 minutes."
        }
    }

    private struct BottleFeedQuickLogSheetView: View {
        let saveAction: (_ amountMilliliters: Int, _ occurredAt: Date, _ milkType: MilkType?) -> Bool

        @Environment(\.dismiss) private var dismiss
        @State private var amountMilliliters = "120"
        @State private var occurredAt = Date()
        @State private var milkType = MilkTypeChoice.notSet

        var body: some View {
            NavigationStack {
                Form {
                    Section("Feed") {
                        TextField("Amount (mL)", text: $amountMilliliters)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("bottle-feed-amount-field")

                        DatePicker(
                            "Time",
                            selection: $occurredAt,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .accessibilityIdentifier("bottle-feed-time-picker")

                        Picker("Milk Type", selection: $milkType) {
                            ForEach(MilkTypeChoice.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .accessibilityIdentifier("bottle-feed-milk-type-picker")
                    }

                    if let validationMessage {
                        Section {
                            Text(validationMessage)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .navigationTitle("Bottle Feed")
                .navigationBarTitleDisplayMode(.inline)
                .presentationDetents([.medium])
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            guard let amountValue = parsedAmountMilliliters else {
                                return
                            }

                            let didSave = saveAction(amountValue, occurredAt, milkType.value)
                            if didSave {
                                dismiss()
                            }
                        }
                        .disabled(parsedAmountMilliliters == nil)
                        .accessibilityIdentifier("save-bottle-feed-button")
                    }
                }
            }
        }

        private var parsedAmountMilliliters: Int? {
            guard let amountValue = Int(amountMilliliters.trimmingCharacters(in: .whitespacesAndNewlines)),
                  amountValue > 0 else {
                return nil
            }

            return amountValue
        }

        private var validationMessage: String? {
            guard !amountMilliliters.isEmpty, parsedAmountMilliliters == nil else {
                return nil
            }

            return "Enter an amount greater than 0 mL."
        }
    }

    private enum BreastSideChoice: String, CaseIterable, Identifiable {
        case notSet
        case left
        case right
        case both

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .notSet:
                "Not Set"
            case .left:
                "Left"
            case .right:
                "Right"
            case .both:
                "Both"
            }
        }

        var value: BreastSide? {
            switch self {
            case .notSet:
                nil
            case .left:
                .left
            case .right:
                .right
            case .both:
                .both
            }
        }
    }

    private enum MilkTypeChoice: String, CaseIterable, Identifiable {
        case notSet
        case breastMilk
        case formula
        case mixed
        case other

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .notSet:
                "Not Set"
            case .breastMilk:
                "Breast Milk"
            case .formula:
                "Formula"
            case .mixed:
                "Mixed"
            case .other:
                "Other"
            }
        }

        var value: MilkType? {
            switch self {
            case .notSet:
                nil
            case .breastMilk:
                .breastMilk
            case .formula:
                .formula
            case .mixed:
                .mixed
            case .other:
                .other
            }
        }
    }
}
