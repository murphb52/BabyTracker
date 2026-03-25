import BabyTrackerDomain
import SwiftUI

public struct ChildWorkspaceTabView: View {
    let model: AppModel
    let profile: ChildProfileScreenState

    @State private var selectedTab: Tab = .home
    @State private var activeEventSheet: ChildEventSheet?
    @State private var deleteCandidate: EventDeleteCandidate?
    @State private var showingEditChildSheet = false

    public init(
        model: AppModel,
        profile: ChildProfileScreenState
    ) {
        self.model = model
        self.profile = profile
    }

    public var body: some View {
        @Bindable var bindableModel = model

        TabView(selection: $selectedTab) {
            ChildHomeView(
                profile: profile,
                quickLogBreastFeed: { activeEventSheet = .quickLogBreastFeed },
                quickLogBottleFeed: { activeEventSheet = .quickLogBottleFeed },
                quickLogSleep: showSleepSheet,
                quickLogNappy: { type in
                    activeEventSheet = .quickLogNappy(type)
                }
            )
            .tag(Tab.home)
            .tabItem {
                Label("Home", systemImage: "house")
            }

            EventHistoryView(
                profile: profile,
                openEvent: showEventSheet(for:),
                deleteEvent: confirmDelete(for:),
                pendingDeleteEvent: deleteCandidate,
                confirmDelete: performDelete,
                cancelDelete: cancelDelete
            )
            .tag(Tab.events)
            .tabItem {
                Label("Events", systemImage: "list.bullet.rectangle")
            }

            TimelineScreenView(
                model: model,
                profile: profile,
                openEvent: showEventSheet(for:),
                deleteEvent: confirmDelete(for:),
                pendingDeleteEvent: deleteCandidate,
                confirmDelete: performDelete,
                cancelDelete: cancelDelete
            )
            .tag(Tab.timeline)
            .tabItem {
                Label("Timeline", systemImage: "calendar")
            }

            ChildProfileView(
                model: model,
                profile: profile,
                editChildAction: { showingEditChildSheet = true },
                shareChildAction: { model.presentShareSheet() },
                archiveAction: { model.archiveCurrentChild() }
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
    }

    private func showSleepSheet() {
        if let activeSleepSession = profile.activeSleepSession {
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

    private func showEventSheet(for event: TimelineEventBlockViewState) {
        activeEventSheet = ChildEventSheet(id: event.id, actionPayload: event.actionPayload)
    }

    private func confirmDelete(for event: EventCardViewState) {
        deleteCandidate = EventDeleteCandidate(event: event)
    }

    private func confirmDelete(for event: TimelineEventBlockViewState) {
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
        case let .startSleep(suggestions):
            SleepEditorSheetView(
                mode: .start,
                initialStartedAt: Date(),
                initialEndedAt: nil,
                startSuggestions: suggestions
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
                initialDurationMinutes: durationMinutes,
                initialEndTime: endTime,
                initialSide: side,
                initialLeftDurationSeconds: leftDurationSeconds,
                initialRightDurationSeconds: rightDurationSeconds
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
        case let .editNappy(id, type, occurredAt, peeVolume, pooVolume, pooColor):
            NappyEditorSheetView(
                navigationTitle: "Edit Nappy",
                primaryActionTitle: "Update",
                initialType: type,
                initialOccurredAt: occurredAt,
                initialPeeVolume: peeVolume,
                initialPooVolume: pooVolume,
                initialPooColor: pooColor
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

extension ChildWorkspaceTabView {
    public enum Tab: Hashable {
        case home
        case events
        case timeline
        case profile
    }
}
