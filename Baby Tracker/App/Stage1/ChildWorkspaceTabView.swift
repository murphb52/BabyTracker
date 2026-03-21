import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildWorkspaceTabView: View {
    let model: AppModel
    let profile: ChildProfileScreenState

    @State private var selectedTab: Tab = .home
    @State private var activeEventSheet: ChildEventSheet?
    @State private var deleteCandidate: EventDeleteCandidate?
    @State private var showingQuickLogNappyTypeDialog = false
    @State private var showingEditChildSheet = false
    @State private var showingArchiveConfirmation = false

    var body: some View {
        @Bindable var bindableModel = model

        TabView(selection: $selectedTab) {
            ChildHomeView(
                profile: profile,
                quickLogBreastFeed: { activeEventSheet = .quickLogBreastFeed },
                quickLogBottleFeed: { activeEventSheet = .quickLogBottleFeed },
                quickLogSleep: showSleepSheet,
                quickLogNappy: { showingQuickLogNappyTypeDialog = true },
                openEvent: showEventSheet(for:),
                deleteEvent: confirmDelete(for:)
            )
            .tag(Tab.home)
            .tabItem {
                Label("Home", systemImage: "house")
            }

            EventHistoryView(
                profile: profile,
                openEvent: showEventSheet(for:),
                deleteEvent: confirmDelete(for:)
            )
            .tag(Tab.events)
            .tabItem {
                Label("Events", systemImage: "list.bullet.rectangle")
            }

            TimelineScreenView(
                model: model,
                profile: profile,
                openEvent: showEventSheet(for:),
                deleteEvent: confirmDelete(for:)
            )
            .tag(Tab.timeline)
            .tabItem {
                Label("Timeline", systemImage: "calendar")
            }

            ChildProfileView(
                model: model,
                profile: profile,
                archiveAction: { showingArchiveConfirmation = true }
            )
                .tag(Tab.profile)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .navigationTitle(profile.child.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeEventSheet, onDismiss: {
            activeEventSheet = nil
        }) { sheet in
            eventSheet(for: sheet)
        }
        .sheet(isPresented: $showingEditChildSheet) {
            ChildEditSheetView(
                initialName: profile.child.name,
                initialBirthDate: profile.child.birthDate,
                saveAction: model.updateCurrentChild(name:birthDate:)
            )
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
        .confirmationDialog(
            deleteCandidate?.dialogTitle ?? "Delete Event?",
            isPresented: deleteConfirmationIsPresented,
            titleVisibility: .visible,
            presenting: deleteCandidate
        ) { event in
            Button(event.confirmButtonTitle, role: .destructive) {
                _ = model.deleteEvent(id: event.id)
                deleteCandidate = nil
            }
        } message: { event in
            Text("Delete \(event.title.lowercased()) from \(event.timestampText)?")
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

    private func showSleepSheet() {
        if let activeSleepSession = profile.activeSleepSession {
            activeEventSheet = .endSleep(
                id: activeSleepSession.id,
                startedAt: activeSleepSession.startedAt
            )
        } else {
            activeEventSheet = .startSleep
        }
    }

    private func showEventSheet(for event: EventCardViewState) {
        activeEventSheet = ChildEventSheet(id: event.id, actionPayload: event.actionPayload)
    }

    private func showEventSheet(for event: TimelineEventBlockViewState) {
        activeEventSheet = ChildEventSheet(id: event.id, actionPayload: event.actionPayload)
    }

    private func confirmDelete(for event: EventCardViewState) {
        deleteCandidate = EventDeleteCandidate(event: event)
    }

    private func confirmDelete(for event: TimelineEventBlockViewState) {
        deleteCandidate = EventDeleteCandidate(event: event)
    }

    @ViewBuilder
    private func eventSheet(for sheet: ChildEventSheet) -> some View {
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
        case let .endSleep(id, startedAt):
            SleepEditorSheetView(
                mode: .end,
                initialStartedAt: startedAt,
                initialEndedAt: defaultSleepEndTime(for: startedAt),
                saveAction: { updatedStartedAt, updatedEndedAt in
                    guard let updatedEndedAt else {
                        return false
                    }

                    let didSave = model.endSleep(
                        id: id,
                        startedAt: updatedStartedAt,
                        endedAt: updatedEndedAt
                    )
                    if didSave {
                        activeEventSheet = nil
                    }
                    return didSave
                },
                deleteAction: profile.canManageEvents ? {
                    if model.deleteEvent(id: id) {
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
}

extension ChildWorkspaceTabView {
    enum Tab: Hashable {
        case home
        case events
        case timeline
        case profile
    }
}
