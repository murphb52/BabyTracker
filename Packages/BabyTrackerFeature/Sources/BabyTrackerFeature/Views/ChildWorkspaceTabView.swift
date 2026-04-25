import BabyTrackerDomain
import SwiftUI

public struct ChildWorkspaceTabView: View {
    let model: AppModel

    @State private var activeEventSheet: ChildEventSheet?
    @State private var activeGroupedTimelineSheet: TimelineDayGridItemViewState?
    @State private var deleteCandidate: EventDeleteCandidate?
    @State private var showingEditChildSheet = false
    @State private var showingEventFilter = false
    @State private var handledSleepSheetRequestToken = 0
    @State private var summaryViewModel: SummaryViewModel
    @State private var eventHistoryViewModel: EventHistoryViewModel
    @State private var homeViewModel: HomeViewModel
    @State private var timelineViewModel: TimelineViewModel
    @State private var childProfileViewModel: ChildProfileViewModel

    public init(model: AppModel) {
        self.model = model
        _summaryViewModel = State(initialValue: SummaryViewModel(appModel: model))
        _eventHistoryViewModel = State(initialValue: EventHistoryViewModel(appModel: model))
        _homeViewModel = State(initialValue: HomeViewModel(appModel: model))
        _timelineViewModel = State(initialValue: TimelineViewModel(appModel: model))
        _childProfileViewModel = State(initialValue: ChildProfileViewModel(appModel: model))
    }

    public var body: some View {
        @Bindable var bindableModel = model

        TabView(selection: $bindableModel.selectedWorkspaceTab) {
            ChildHomeView(
                model: model,
                viewModel: homeViewModel,
                childProfileViewModel: childProfileViewModel,
                stopSleep: showSleepSheet,
                logPastSleep: { activeEventSheet = .logPastSleep(suggestions: model.sleepStartSuggestions()) },
                quickLogBreastFeed: { activeEventSheet = .quickLogBreastFeed },
                quickLogBottleFeed: { activeEventSheet = .quickLogBottleFeed },
                quickLogSleep: showSleepSheet,
                quickLogNappy: {
                    activeEventSheet = .quickLogNappy(.mixed)
                },
                openProfile: { showingEditChildSheet = true }
            )
            .tag(ChildWorkspaceTab.home)
            .tabItem {
                Label("Home", systemImage: "house")
            }

            EventHistoryView(
                viewModel: eventHistoryViewModel,
                canManageEvents: childProfileViewModel.canManageEvents,
                openEvent: showEventSheet(for:),
                deleteEvent: confirmDelete(for:),
                pendingDeleteEvent: deleteCandidate,
                confirmDelete: performDelete,
                cancelDelete: cancelDelete,
                onRefresh: model.forceFullSyncRefresh
            )
            .tag(ChildWorkspaceTab.events)
            .tabItem {
                Label("Events", systemImage: "list.bullet.rectangle")
            }

            TimelineScreenView(
                viewModel: timelineViewModel,
                openEvent: showEventSheet(for:),
                deleteEvent: confirmDelete(for:),
                pendingDeleteEvent: deleteCandidate,
                confirmDelete: performDelete,
                cancelDelete: cancelDelete
            )
            .tag(ChildWorkspaceTab.timeline)
            .tabItem {
                Label("Timeline", systemImage: "calendar")
            }

            SummaryScreenView(viewModel: summaryViewModel)
            .tag(ChildWorkspaceTab.summary)
            .tabItem {
                Label("Summary", systemImage: "chart.bar.fill")
            }

            ChildProfileView(
                model: model,
                viewModel: childProfileViewModel,
                editChildAction: { showingEditChildSheet = true },
                shareChildAction: { model.presentShareSheet() },
                archiveAction: { model.archiveCurrentChild() },
                hardDeleteAction: { model.hardDeleteCurrentChild() }
            )
            .tag(ChildWorkspaceTab.profile)
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
        .navigationTitle(childProfileViewModel.childName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if model.selectedWorkspaceTab == .home, let initials = childInitials {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingEditChildSheet = true }) {
                        Text(initials)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.tint)
                            .frame(width: 34, height: 34)
                            .background(.tint.opacity(0.12), in: Circle())
                            .overlay(Circle().stroke(.tint.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            if model.selectedWorkspaceTab == .events {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEventFilter = true
                    } label: {
                        Image(systemName: eventHistoryViewModel.filterIsActive
                            ? "line.3.horizontal.decrease.circle.fill"
                            : "line.3.horizontal.decrease.circle")
                    }
                    .tint(eventHistoryViewModel.filterIsActive ? .accentColor : nil)
                    .accessibilityIdentifier("event-history-filter-button")
                }
            }
            if model.selectedWorkspaceTab == .timeline {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(timelineViewModel.displayMode == .day ? "Week View" : "Day View") {
                        timelineViewModel.toggleDisplayMode()
                    }
                    .buttonStyle(.automatic)
                    .accessibilityIdentifier("timeline-display-mode-button")
                }
            }
        }
        .sheet(item: $activeEventSheet, onDismiss: {
            activeEventSheet = nil
        }) { sheet in
            eventSheet(for: sheet)
        }
        .sheet(item: $activeGroupedTimelineSheet, onDismiss: {
            activeGroupedTimelineSheet = nil
        }) { item in
            TimelineDayGridGroupedEventsSheetView(
                item: item,
                canManageEvents: childProfileViewModel.canManageEvents,
                openEvent: { entry in
                    activeGroupedTimelineSheet = nil
                    showEventSheet(for: entry)
                }
            )
        }
        .sheet(isPresented: $showingEventFilter) {
            EventFilterView(currentFilter: eventHistoryViewModel.activeFilter) { newFilter in
                eventHistoryViewModel.updateFilter(newFilter)
            }
        }
        .sheet(isPresented: $showingEditChildSheet) {
            ChildEditSheetView(
                initialName: childProfileViewModel.childName,
                initialBirthDate: childProfileViewModel.child?.birthDate,
                initialImageData: childProfileViewModel.child?.imageData,
                saveAction: { name, birthDate, imageData in
                    model.updateCurrentChild(name: name, birthDate: birthDate, imageData: imageData)
                }
            )
        }
        .sheet(item: $bindableModel.shareSheetState) { shareState in
            CloudKitShareSheetView(
                shareState: shareState,
                childName: childProfileViewModel.childName,
                onSaveFailure: model.handleShareSheetSaveFailure
            )
                .onDisappear {
                    model.dismissShareSheet()
                    model.refreshAfterShareSheet()
                }
        }
        .onAppear {
            processPendingSleepSheetRequest()
        }
        .onChange(of: model.sleepSheetRequestToken) { _, _ in
            processPendingSleepSheetRequest()
        }
    }

    private var childInitials: String? {
        let name = childProfileViewModel.childName
        guard !name.isEmpty else { return nil }
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return words.prefix(2).compactMap { $0.first.map(String.init) }.joined()
        }
        return String(name.prefix(1))
    }

    private func processPendingSleepSheetRequest() {
        guard model.sleepSheetRequestToken > handledSleepSheetRequestToken else {
            return
        }

        handledSleepSheetRequestToken = model.sleepSheetRequestToken
        showSleepSheet()
    }

    private func showSleepSheet() {
        if let activeSleepSession = homeViewModel.activeSleepSession {
            activeEventSheet = .endSleep(
                id: activeSleepSession.id,
                startedAt: activeSleepSession.startedAt
            )
        } else {
            activeEventSheet = .startSleep(suggestions: model.sleepStartSuggestions())
        }
    }

    private func showEventSheet(for event: EventCardViewState) {
        activeEventSheet = ChildEventSheet(id: event.id, actionPayload: event.actionPayload)
    }

    private func showEventSheet(for event: TimelineDayGridItemViewState) {
        if event.opensGroupedSheet {
            activeGroupedTimelineSheet = event
            return
        }

        guard let eventID = event.primaryEventID,
              let actionPayload = event.primaryActionPayload,
              event.isInteractive else {
            return
        }

        activeEventSheet = ChildEventSheet(id: eventID, actionPayload: actionPayload)
    }

    private func confirmDelete(for event: EventCardViewState) {
        deleteCandidate = EventDeleteCandidate(event: event)
    }

    private func confirmDelete(for event: TimelineDayGridItemViewState) {
        guard event.isInteractive else {
            return
        }

        deleteCandidate = EventDeleteCandidate(event: event)
    }

    private func performDelete() {
        guard let deleteCandidate else {
            return
        }

        _ = model.deleteEvent(id: deleteCandidate.id)
        self.deleteCandidate = nil
    }

    private func cancelDelete() {
        deleteCandidate = nil
    }

    @ViewBuilder
    private func eventSheet(for sheet: ChildEventSheet) -> some View {
        switch sheet {
        case .quickLogBreastFeed:
            BreastFeedEditorSheetView(
                navigationTitle: "Breast Feed",
                primaryActionTitle: "Save",
                childName: childProfileViewModel.childName,
                initialDurationMinutes: 15,
                initialEndTime: Date(),
                initialSide: nil
            ) { durationMinutes, endTime, side, leftDurationSeconds, rightDurationSeconds in
                let didSave = model.logBreastFeed(
                    durationMinutes: durationMinutes,
                    endTime: endTime,
                    side: side,
                    leftDurationSeconds: leftDurationSeconds,
                    rightDurationSeconds: rightDurationSeconds
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
                childName: childProfileViewModel.childName,
                preferredVolumeUnit: childProfileViewModel.child?.preferredFeedVolumeUnit ?? .milliliters,
                initialAmountMilliliters: 120,
                initialOccurredAt: Date(),
                initialMilkType: .formula
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
        case let .startSleep(suggestions):
            SleepEditorSheetView(
                mode: .start,
                childName: childProfileViewModel.childName,
                initialStartedAt: Date(),
                initialEndedAt: nil,
                startSuggestions: suggestions
            ) { startedAt, endedAt in
                let didSave: Bool
                if let endedAt {
                    didSave = model.logSleep(startedAt: startedAt, endedAt: endedAt)
                } else {
                    didSave = model.startSleep(startedAt: startedAt)
                }
                if didSave {
                    activeEventSheet = nil
                }
                return didSave
            }
        case let .logPastSleep(suggestions):
            SleepEditorSheetView(
                mode: .start,
                childName: childProfileViewModel.childName,
                initialStartedAt: Date(),
                initialEndedAt: nil,
                startSuggestions: suggestions,
                initialIncludesEndTime: true
            ) { startedAt, endedAt in
                guard let endedAt else { return false }
                let didSave = model.logSleep(startedAt: startedAt, endedAt: endedAt)
                if didSave {
                    activeEventSheet = nil
                }
                return didSave
            }
        case let .endSleep(id, startedAt):
            SleepEditorSheetView(
                mode: .end,
                childName: childProfileViewModel.childName,
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
                deleteAction: childProfileViewModel.canManageEvents ? {
                    if model.deleteEvent(id: id) {
                        activeEventSheet = nil
                    }
                } : nil
            )
        case let .quickLogNappy(type):
            NappyEditorSheetView(
                navigationTitle: "Nappy",
                primaryActionTitle: "Save",
                childName: childProfileViewModel.childName,
                initialType: type,
                initialOccurredAt: Date(),
                initialPeeVolume: nil,
                initialPooVolume: nil,
                initialPooColor: nil
            ) { updatedType, occurredAt, peeVolume, pooVolume, pooColor in
                let didSave = model.logNappy(
                    type: updatedType,
                    occurredAt: occurredAt,
                    peeVolume: peeVolume,
                    pooVolume: pooVolume,
                    pooColor: pooColor
                )
                if didSave {
                    activeEventSheet = nil
                }
                return didSave
            }
        case let .editBreastFeed(id, durationMinutes, endTime, side, leftDurationSeconds, rightDurationSeconds):
            BreastFeedEditorSheetView(
                navigationTitle: "Edit Breast Feed",
                primaryActionTitle: "Update",
                childName: childProfileViewModel.childName,
                initialDurationMinutes: durationMinutes,
                initialEndTime: endTime,
                initialSide: side,
                allowsTimerMode: false,
                initialTimePreset: .custom,
                initialLeftDurationSeconds: leftDurationSeconds,
                initialRightDurationSeconds: rightDurationSeconds,
                deleteAction: childProfileViewModel.canManageEvents ? {
                    if model.deleteEvent(id: id) {
                        activeEventSheet = nil
                    }
                } : nil
            ) { updatedDuration, updatedEndTime, updatedSide, updatedLeft, updatedRight in
                let didSave = model.updateBreastFeed(
                    id: id,
                    durationMinutes: updatedDuration,
                    endTime: updatedEndTime,
                    side: updatedSide,
                    leftDurationSeconds: updatedLeft,
                    rightDurationSeconds: updatedRight
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
                childName: childProfileViewModel.childName,
                preferredVolumeUnit: childProfileViewModel.child?.preferredFeedVolumeUnit ?? .milliliters,
                initialAmountMilliliters: amountMilliliters,
                initialOccurredAt: occurredAt,
                initialMilkType: milkType,
                initialTimePreset: .custom,
                showCustomAmountOnOpen: true,
                deleteAction: childProfileViewModel.canManageEvents ? {
                    if model.deleteEvent(id: id) {
                        activeEventSheet = nil
                    }
                } : nil
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
                childName: childProfileViewModel.childName,
                initialStartedAt: startedAt,
                initialEndedAt: endedAt,
                endTimeInitialPreset: .custom,
                saveAction: { updatedStartedAt, updatedEndedAt in
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
                },
                deleteAction: childProfileViewModel.canManageEvents ? {
                    if model.deleteEvent(id: id) {
                        activeEventSheet = nil
                    }
                } : nil,
                resumeAction: {
                    let didResume = model.resumeSleep(id: id, startedAt: startedAt)
                    if didResume {
                        activeEventSheet = nil
                    }
                }
            )
        case let .editNappy(id, type, occurredAt, peeVolume, pooVolume, pooColor):
            NappyEditorSheetView(
                navigationTitle: "Edit Nappy",
                primaryActionTitle: "Update",
                childName: childProfileViewModel.childName,
                initialType: type,
                initialOccurredAt: occurredAt,
                initialPeeVolume: peeVolume,
                initialPooVolume: pooVolume,
                initialPooColor: pooColor,
                initialTimePreset: .custom,
                deleteAction: childProfileViewModel.canManageEvents ? {
                    if model.deleteEvent(id: id) {
                        activeEventSheet = nil
                    }
                } : nil
            ) { updatedType, updatedOccurredAt, updatedPeeVolume, updatedPooVolume, updatedPooColor in
                let didSave = model.updateNappy(
                    id: id,
                    type: updatedType,
                    occurredAt: updatedOccurredAt,
                    peeVolume: updatedPeeVolume,
                    pooVolume: updatedPooVolume,
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
            return startedAt.addingTimeInterval(1)
        }

        return max(now, startedAt.addingTimeInterval(1))
    }
}
