import BabyTrackerDomain
import BabyTrackerPersistence
import BabyTrackerSync
import Foundation
import Observation
import os

@MainActor
@Observable
public final class AppModel {
    public private(set) var route: AppRoute = .loading
    public private(set) var localUser: UserIdentity?
    public private(set) var activeChildren: [ChildSummary] = []
    public private(set) var archivedChildren: [ChildSummary] = []
    public private(set) var profile: ChildProfileScreenState?
    public private(set) var errorMessage: String?
    public private(set) var undoDeleteMessage: String?
    public var shareSheetState: ShareSheetState?
    public private(set) var csvImportState: CSVImportState = .idle
    public private(set) var nestImportState: NestImportState = .idle
    public private(set) var dataExportState: DataExportState = .idle

    private let logger = Logger(subsystem: "com.adappt.BabyTracker", category: "AppModel")
    private let childRepository: any ChildRepository
    private let userIdentityRepository: any UserIdentityRepository
    private let membershipRepository: any MembershipRepository
    private let childSelectionStore: any ChildSelectionStore
    private let eventRepository: EventRepository
    private let syncEngine: CloudKitSyncEngine
    private let liveActivityManager: any FeedLiveActivityManaging
    private let buildTimelineStripDatasetUseCase = BuildTimelineStripDatasetUseCase()
    private let calendar = Calendar.autoupdatingCurrent
    private var timelineSelectedDay = Calendar.autoupdatingCurrent.startOfDay(for: .now)
    private var timelineDisplayMode: TimelineScreenState.DisplayMode = .day
    private var timelineChildID: UUID?
    private var activeEventFilter: EventFilter = .empty
    private var pendingUndoDeletedEvent: BabyEvent?
    private var undoDeleteTask: Task<Void, Never>?

    public init(
        childRepository: any ChildRepository,
        userIdentityRepository: any UserIdentityRepository,
        membershipRepository: any MembershipRepository,
        childSelectionStore: any ChildSelectionStore,
        eventRepository: EventRepository,
        syncEngine: CloudKitSyncEngine,
        liveActivityManager: any FeedLiveActivityManaging = NoOpFeedLiveActivityManager()
    ) {
        self.childRepository = childRepository
        self.userIdentityRepository = userIdentityRepository
        self.membershipRepository = membershipRepository
        self.childSelectionStore = childSelectionStore
        self.eventRepository = eventRepository
        self.syncEngine = syncEngine
        self.liveActivityManager = liveActivityManager
    }

    public func load(performLaunchSync: Bool = true) {
        refresh(selecting: nil)

        guard performLaunchSync else {
            return
        }

        Task { @MainActor in
            _ = await syncEngine.prepareForLaunch()
            refresh(selecting: childSelectionStore.loadSelectedChildID())
        }
    }

    public func dismissError() {
        errorMessage = nil
    }

    public func dismissShareSheet() {
        shareSheetState = nil
    }

    public func refreshAfterShareSheet() {
        Task { @MainActor in
            _ = await syncEngine.refreshForeground()
            refresh(selecting: childSelectionStore.loadSelectedChildID())
        }
    }

    public func refreshSyncStatus() {
        Task { @MainActor in
            _ = await syncEngine.refreshForeground()
            refresh(selecting: childSelectionStore.loadSelectedChildID())
        }
    }

    public func hardDeleteAllData() {
        Task { @MainActor in
            var cloudDeleteError: Error?

            do {
                try await syncEngine.hardDeleteAllCloudData()
            } catch {
                cloudDeleteError = error
                AppLogger.shared.log(.error, category: "CloudKitSync", "Hard delete cloud cleanup failed: \(error.localizedDescription)")
            }

            do {
                try userIdentityRepository.resetAllData()
                childSelectionStore.saveSelectedChildID(nil)
                clearUndoDeleteState()
                refresh(selecting: nil)
                if let cloudDeleteError {
                    errorMessage = "Local data was cleared, but iCloud cleanup failed: \(cloudDeleteError.localizedDescription)"
                }
            } catch {
                errorMessage = resolveErrorMessage(for: error)
                refresh(selecting: nil)
            }
        }
    }

    public func createLocalUser(displayName: String) {
        perform {
            _ = try CreateLocalUserUseCase(userIdentityRepository: userIdentityRepository)
                .execute(.init(displayName: displayName))
        }
    }

    public func createChild(name: String, birthDate: Date?, imageData: Data? = nil) {
        perform {
            guard let localUser else { return }
            _ = try CreateChildUseCase(
                childRepository: childRepository,
                membershipRepository: membershipRepository,
                childSelectionStore: childSelectionStore
            ).execute(.init(name: name, birthDate: birthDate, localUser: localUser, imageData: imageData))
        }
    }

    public func updateCurrentChild(name: String, birthDate: Date?, imageData: Data? = nil) {
        perform {
            guard let profile else { return }
            _ = try UpdateCurrentChildUseCase(childRepository: childRepository)
                .execute(.init(
                    child: profile.child,
                    name: name,
                    birthDate: birthDate,
                    membership: profile.currentMembership,
                    imageData: imageData
                ))
        }
    }

    public func archiveCurrentChild() {
        perform {
            guard let profile else { return }
            try ArchiveCurrentChildUseCase(
                childRepository: childRepository,
                childSelectionStore: childSelectionStore
            ).execute(.init(
                child: profile.child,
                membership: profile.currentMembership,
                currentSelectedChildID: childSelectionStore.loadSelectedChildID()
            ))
        }
    }

    public func restoreChild(id: UUID) {
        perform {
            _ = try RestoreChildUseCase(
                childRepository: childRepository,
                childSelectionStore: childSelectionStore
            ).execute(.init(childID: id))
        }
    }

    public func selectChild(id: UUID) {
        childSelectionStore.saveSelectedChildID(id)
        timelineChildID = id
        timelineSelectedDay = normalizedTimelineDay(for: .now)
        refresh(selecting: id)
    }

    public func showPreviousTimelineDay() {
        guard let previousDay = calendar.date(
            byAdding: .day,
            value: -1,
            to: timelineSelectedDay
        ) else {
            return
        }

        timelineSelectedDay = normalizedTimelineDay(for: previousDay)
        refresh(selecting: childSelectionStore.loadSelectedChildID())
    }

    public func showNextTimelineDay() {
        guard let nextDay = calendar.date(
            byAdding: .day,
            value: 1,
            to: timelineSelectedDay
        ) else {
            return
        }

        timelineSelectedDay = normalizedTimelineDay(for: nextDay)
        refresh(selecting: childSelectionStore.loadSelectedChildID())
    }

    public func jumpTimelineToToday() {
        timelineSelectedDay = normalizedTimelineDay(for: .now)
        refresh(selecting: childSelectionStore.loadSelectedChildID())
    }

    public func showTimelineDay(_ day: Date) {
        timelineSelectedDay = normalizedTimelineDay(for: day)
        refresh(selecting: childSelectionStore.loadSelectedChildID())
    }

    public func toggleTimelineDisplayMode() {
        timelineDisplayMode = timelineDisplayMode == .day ? .week : .day
        refresh(selecting: childSelectionStore.loadSelectedChildID())
    }

    public var eventFilter: EventFilter { activeEventFilter }

    public func updateEventFilter(_ filter: EventFilter) {
        activeEventFilter = filter
        refresh(selecting: childSelectionStore.loadSelectedChildID())
    }

    public func showChildPicker() {
        guard activeChildren.count > 1 else {
            return
        }

        route = .childPicker
    }

    public func presentShareSheet() {
        guard let profile, profile.canShareChild else {
            return
        }

        Task { @MainActor in
            do {
                let presentation = try await syncEngine.prepareShare(
                    for: profile.child.id
                )
                shareSheetState = ShareSheetState(presentation: presentation)
                refresh(selecting: childSelectionStore.loadSelectedChildID())
            } catch {
                errorMessage = resolveErrorMessage(for: error)
            }
        }
    }

    public func removeCaregiver(membershipID: UUID) {
        guard let profile else {
            return
        }

        perform {
            let removedMembership = try RemoveCaregiverUseCase(membershipRepository: membershipRepository)
                .execute(.init(
                    membershipID: membershipID,
                    childID: profile.child.id,
                    actingMembership: profile.currentMembership
                ))

            Task { @MainActor in
                try? await syncEngine.removeParticipant(membership: removedMembership)
                refresh(selecting: childSelectionStore.loadSelectedChildID())
            }
        }
    }

    public func leaveChildShare() {
        guard let profile, profile.canLeaveShare else { return }
        let childID = profile.child.id
        Task { @MainActor in
            do {
                try await syncEngine.leaveShare(childID: childID)
                try childRepository.purgeChildData(id: childID)
                if childSelectionStore.loadSelectedChildID() == childID {
                    childSelectionStore.saveSelectedChildID(nil)
                }
            } catch {
                errorMessage = resolveErrorMessage(for: error)
            }
            refresh(selecting: childSelectionStore.loadSelectedChildID())
        }
    }

    @discardableResult
    public func logBreastFeed(
        durationMinutes: Int,
        endTime: Date,
        side: BreastSide?,
        leftDurationSeconds: Int? = nil,
        rightDurationSeconds: Int? = nil
    ) -> Bool {
        perform {
            guard let profile else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            _ = try LogBreastFeedUseCase(eventRepository: eventRepository)
                .execute(.init(
                    childID: profile.child.id,
                    localUserID: localUser.id,
                    durationMinutes: durationMinutes,
                    endTime: endTime,
                    side: side,
                    leftDurationSeconds: leftDurationSeconds,
                    rightDurationSeconds: rightDurationSeconds,
                    membership: profile.currentMembership
                ))
        }
    }

    @discardableResult
    public func logBottleFeed(
        amountMilliliters: Int,
        occurredAt: Date,
        milkType: MilkType?
    ) -> Bool {
        perform {
            guard let profile else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            _ = try LogBottleFeedUseCase(eventRepository: eventRepository)
                .execute(.init(
                    childID: profile.child.id,
                    localUserID: localUser.id,
                    amountMilliliters: amountMilliliters,
                    occurredAt: occurredAt,
                    milkType: milkType,
                    membership: profile.currentMembership
                ))
        }
    }

    @discardableResult
    public func logNappy(
        type: NappyType,
        occurredAt: Date,
        peeVolume: NappyVolume? = nil,
        pooVolume: NappyVolume? = nil,
        pooColor: PooColor? = nil
    ) -> Bool {
        perform {
            guard let profile else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            _ = try LogNappyUseCase(eventRepository: eventRepository)
                .execute(.init(
                    childID: profile.child.id,
                    localUserID: localUser.id,
                    type: type,
                    occurredAt: occurredAt,
                    peeVolume: peeVolume,
                    pooVolume: pooVolume,
                    pooColor: pooColor,
                    membership: profile.currentMembership
                ))
        }
    }

    @discardableResult
    public func startSleep(startedAt: Date) -> Bool {
        perform {
            guard let profile else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            _ = try StartSleepUseCase(eventRepository: eventRepository)
                .execute(.init(
                    childID: profile.child.id,
                    localUserID: localUser.id,
                    startedAt: startedAt,
                    membership: profile.currentMembership
                ))
        }
    }

    @discardableResult
    public func logSleep(startedAt: Date, endedAt: Date) -> Bool {
        perform {
            guard let profile else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            _ = try LogSleepUseCase(eventRepository: eventRepository)
                .execute(.init(
                    childID: profile.child.id,
                    localUserID: localUser.id,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    membership: profile.currentMembership
                ))
        }
    }

    @discardableResult
    public func endSleep(
        id: UUID,
        startedAt: Date,
        endedAt: Date
    ) -> Bool {
        perform {
            guard let profile else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            _ = try EndSleepUseCase(eventRepository: eventRepository)
                .execute(.init(
                    eventID: id,
                    localUserID: localUser.id,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    membership: profile.currentMembership
                ))
        }
    }

    @discardableResult
    public func updateBreastFeed(
        id: UUID,
        durationMinutes: Int,
        endTime: Date,
        side: BreastSide?,
        leftDurationSeconds: Int? = nil,
        rightDurationSeconds: Int? = nil
    ) -> Bool {
        perform {
            guard let profile else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            try UpdateBreastFeedUseCase(eventRepository: eventRepository)
                .execute(.init(
                    eventID: id,
                    localUserID: localUser.id,
                    durationMinutes: durationMinutes,
                    endTime: endTime,
                    side: side,
                    leftDurationSeconds: leftDurationSeconds,
                    rightDurationSeconds: rightDurationSeconds,
                    membership: profile.currentMembership
                ))
        }
    }

    @discardableResult
    public func updateBottleFeed(
        id: UUID,
        amountMilliliters: Int,
        occurredAt: Date,
        milkType: MilkType?
    ) -> Bool {
        perform {
            guard let profile else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            try UpdateBottleFeedUseCase(eventRepository: eventRepository)
                .execute(.init(
                    eventID: id,
                    localUserID: localUser.id,
                    amountMilliliters: amountMilliliters,
                    occurredAt: occurredAt,
                    milkType: milkType,
                    membership: profile.currentMembership
                ))
        }
    }

    @discardableResult
    public func updateNappy(
        id: UUID,
        type: NappyType,
        occurredAt: Date,
        peeVolume: NappyVolume? = nil,
        pooVolume: NappyVolume? = nil,
        pooColor: PooColor? = nil
    ) -> Bool {
        perform {
            guard let profile else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            try UpdateNappyUseCase(eventRepository: eventRepository)
                .execute(.init(
                    eventID: id,
                    localUserID: localUser.id,
                    type: type,
                    occurredAt: occurredAt,
                    peeVolume: peeVolume,
                    pooVolume: pooVolume,
                    pooColor: pooColor,
                    membership: profile.currentMembership
                ))
        }
    }

    public func sleepStartSuggestions() -> [(label: String, date: Date)] {
        guard let profile else { return [] }
        let timeline = (try? eventRepository.loadTimeline(for: profile.child.id, includingDeleted: false)) ?? []

        var suggestions: [(label: String, date: Date)] = []
        let timeFormatter = Date.FormatStyle(date: .omitted, time: .shortened)

        if case let .bottleFeed(feed) = timeline.first(where: { if case .bottleFeed = $0 { true } else { false } }) {
            suggestions.append((label: "Last bottle at \(feed.metadata.occurredAt.formatted(timeFormatter))", date: feed.metadata.occurredAt))
        }

        if case let .breastFeed(feed) = timeline.first(where: { if case .breastFeed = $0 { true } else { false } }) {
            suggestions.append((label: "Last feed at \(feed.metadata.occurredAt.formatted(timeFormatter))", date: feed.metadata.occurredAt))
        }

        if case let .nappy(nappy) = timeline.first(where: { if case .nappy = $0 { true } else { false } }) {
            suggestions.append((label: "Last nappy at \(nappy.metadata.occurredAt.formatted(timeFormatter))", date: nappy.metadata.occurredAt))
        }

        return suggestions
    }

    @discardableResult
    public func updateSleep(
        id: UUID,
        startedAt: Date,
        endedAt: Date
    ) -> Bool {
        perform {
            guard let profile else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            try UpdateSleepUseCase(eventRepository: eventRepository)
                .execute(.init(
                    eventID: id,
                    localUserID: localUser.id,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    membership: profile.currentMembership
                ))
        }
    }

    @discardableResult
    public func deleteEvent(id: UUID) -> Bool {
        perform {
            guard let profile else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            clearUndoDeleteState()
            if let event = try DeleteEventUseCase(eventRepository: eventRepository)
                .execute(.init(
                    eventID: id,
                    localUserID: localUser.id,
                    membership: profile.currentMembership
                )) {
                pendingUndoDeletedEvent = event
                undoDeleteMessage = "\(eventTitle(for: event)) deleted"
                startUndoDeleteExpiryTask()
            }
        }
    }

    public func undoLastDeletedEvent() {
        perform {
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            guard let pendingUndoDeletedEvent else { return }
            _ = try RestoreDeletedEventUseCase(eventRepository: eventRepository)
                .execute(.init(event: pendingUndoDeletedEvent, restoredBy: localUser.id))
            clearUndoDeleteState()
        }
    }

    @discardableResult
    private func perform(_ operation: () throws -> Void) -> Bool {
        do {
            try operation()
            refresh(selecting: childSelectionStore.loadSelectedChildID())
            Task { @MainActor in
                _ = await syncEngine.refreshAfterLocalWrite()
                refresh(selecting: childSelectionStore.loadSelectedChildID())
            }
            return true
        } catch {
            errorMessage = resolveErrorMessage(for: error)
            refresh(selecting: childSelectionStore.loadSelectedChildID())
            return false
        }
    }

    private func refresh(selecting selectedChildID: UUID?) {
        do {
            localUser = try userIdentityRepository.loadLocalUser()

            guard let localUser else {
                route = .identityOnboarding
                activeChildren = []
                archivedChildren = []
                profile = nil
                timelineChildID = nil
                liveActivityManager.synchronize(with: nil)
                return
            }

            activeChildren = try loadChildSummaries(
                children: childRepository.loadActiveChildren(for: localUser.id),
                userID: localUser.id
            )
            archivedChildren = try loadChildSummaries(
                children: childRepository.loadArchivedChildren(for: localUser.id),
                userID: localUser.id
            )
            logger.info("refresh — localUserID: \(localUser.id, privacy: .public), active: \(self.activeChildren.count, privacy: .public), archived: \(self.archivedChildren.count, privacy: .public)")
            AppLogger.shared.log(.info, category: "AppModel", "refresh — active: \(self.activeChildren.count), archived: \(self.archivedChildren.count)")

            guard !activeChildren.isEmpty else {
                route = .noChildren
                profile = nil
                timelineChildID = nil
                liveActivityManager.synchronize(with: nil)
                return
            }

            let effectiveSelectedChildID = selectedChildID ?? childSelectionStore.loadSelectedChildID()
            let selectedSummary = activeChildren.first(where: { summary in
                summary.child.id == effectiveSelectedChildID
            })

            if activeChildren.count > 1 && selectedSummary == nil {
                route = .childPicker
                profile = nil
                timelineChildID = nil
                liveActivityManager.synchronize(with: nil)
                return
            }

            let currentSummary = selectedSummary ?? activeChildren[0]
            childSelectionStore.saveSelectedChildID(currentSummary.child.id)
            synchronizeTimelineSelection(for: currentSummary.child.id)
            let visibleEvents = try loadVisibleEvents(for: currentSummary.child.id)
            let timelinePages = try loadTimelinePages(
                for: currentSummary.child.id,
                days: timelineVisibleDays(for: timelineSelectedDay)
            )
            let activeSleep = try eventRepository.loadActiveSleepEvent(for: currentSummary.child.id)
            profile = try makeProfile(
                child: currentSummary.child,
                localUser: localUser,
                visibleEvents: visibleEvents,
                timelinePages: timelinePages,
                activeSleep: activeSleep
            )
            route = .childProfile
            liveActivityManager.synchronize(
                with: makeFeedLiveActivitySnapshot(
                    from: visibleEvents,
                    child: currentSummary.child
                )
            )
        } catch {
            errorMessage = resolveErrorMessage(for: error)
            // Only redirect to identity onboarding when there is genuinely no
            // local user. Data errors (e.g. owner membership not yet synced on a
            // shared child) must not wipe out the user's session.
            if localUser == nil {
                route = .identityOnboarding
                liveActivityManager.synchronize(with: nil)
            }
        }
    }

    private func loadChildSummaries(
        children: [Child],
        userID: UUID
    ) throws -> [ChildSummary] {
        var summaries: [ChildSummary] = []

        for child in children {
            let memberships = try membershipRepository.loadMemberships(for: child.id)
            guard let membership = memberships.first(where: { membership in
                membership.userID == userID && membership.status == .active
            }) else {
                let statuses = memberships
                    .filter { $0.userID == userID }
                    .map { "\($0.status)" }
                    .joined(separator: ", ")
                let allRoles = memberships
                    .map { "userID=\($0.userID == userID ? "self" : "other") role=\($0.role) status=\($0.status)" }
                    .joined(separator: "; ")
                logger.warning(
                    "loadChildSummaries — skipping child '\(child.name, privacy: .private)': no active membership for local user. Self statuses: [\(statuses, privacy: .public)]. All memberships: [\(allRoles, privacy: .public)]"
                )
                AppLogger.shared.log(.warning, category: "AppModel", "loadChildSummaries — skipping child: no active membership for local user. Self statuses: [\(statuses)]. All memberships: [\(allRoles)]")
                continue
            }

            summaries.append(ChildSummary(child: child, membership: membership))
        }

        return summaries.sorted { left, right in
            left.child.createdAt < right.child.createdAt
        }
    }

    private func makeProfile(
        child: Child,
        localUser: UserIdentity,
        visibleEvents: [BabyEvent],
        timelinePages: [TimelineDayPageState],
        activeSleep: SleepEvent?
    ) throws -> ChildProfileScreenState {
        let memberships = try membershipRepository.loadMemberships(for: child.id)
        let userIDs = memberships.map(\.userID)
        let users = try userIdentityRepository.loadUsers(for: userIDs)
        let usersByID = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })

        guard let currentMembership = memberships.first(where: { membership in
            membership.userID == localUser.id && membership.status == .active
        }) else {
            throw ChildProfileValidationError.invalidMembershipTransition(
                from: .removed,
                to: .active
            )
        }

        let pairs = memberships.compactMap { membership -> CaregiverMembershipViewState? in
            guard let user = usersByID[membership.userID] else {
                return nil
            }

            return CaregiverMembershipViewState(user: user, membership: membership)
        }

        let owner = pairs.first(where: { pair in
            pair.membership.role == .owner && pair.membership.status == .active
        })

        let activeCaregivers = pairs.filter { pair in
            pair.membership.role == .caregiver && pair.membership.status == .active
        }
        let removedCaregivers = pairs.filter { pair in
            pair.membership.status == .removed
        }

        let pendingShareInvites = syncEngine.pendingInvites(for: child.id).map { invite in
            PendingShareInviteViewState(
                id: invite.id,
                displayName: invite.displayName,
                statusLabel: invite.acceptanceStatus == .pending ? "Pending invitation" : "Invited"
            )
        }
        let canLogEvents = ChildAccessPolicy.canPerform(.logEvent, membership: currentMembership)
        let canManageEvents =
            ChildAccessPolicy.canPerform(.editEvent, membership: currentMembership) &&
            ChildAccessPolicy.canPerform(.deleteEvent, membership: currentMembership)
        let cloudKitStatus = CloudKitStatusViewState(summary: syncEngine.statusSummary)
        let pendingCounts = (try? syncEngine.loadPendingChangeCounts()) ?? [:]
        let pendingChanges: [PendingChangeSummaryItem] = [
            (.breastFeedEvent, "figure.seated.side.air.upper", "Breast feeds"),
            (.bottleFeedEvent, "waterbottle.fill",             "Bottle feeds"),
            (.sleepEvent,      "moon.zzz.fill",                "Sleep sessions"),
            (.nappyEvent,      "checklist.checked",            "Nappy changes"),
            (.membership,      "person.2.fill",                "Sharing info"),
            (.child,           "person.fill",                  "Profile data"),
        ].compactMap { (type, icon, label) in
            guard let count = pendingCounts[type], count > 0 else { return nil }
            return PendingChangeSummaryItem(icon: icon, label: label, count: count)
        }

        return ChildProfileScreenState(
            child: child,
            localUser: localUser,
            currentMembership: currentMembership,
            owner: owner,
            activeCaregivers: activeCaregivers,
            pendingShareInvites: pendingShareInvites,
            removedCaregivers: removedCaregivers,
            canSwitchChildren: activeChildren.count > 1,
            canLogEvents: canLogEvents,
            canManageEvents: canManageEvents,
            activeSleepSession: activeSleep.map(ActiveSleepSessionViewState.init),
            home: makeHomeScreenState(from: visibleEvents, activeSleep: activeSleep),
            eventHistory: makeEventHistoryScreenState(from: visibleEvents),
            timeline: makeTimelineScreenState(
                from: timelinePages,
                selectedDay: timelineSelectedDay,
                timelineEvents: visibleEvents,
                cloudKitStatus: cloudKitStatus
            ),
            summary: makeSummaryScreenState(from: visibleEvents),
            cloudKitStatus: cloudKitStatus,
            canShareChild: ChildAccessPolicy.canPerform(.inviteCaregiver, membership: currentMembership) &&
                syncEngine.statusSummary.state != .failed,
            pendingChanges: pendingChanges
        )
    }

    private func loadVisibleEvents(for childID: UUID) throws -> [BabyEvent] {
        try eventRepository.loadTimeline(for: childID, includingDeleted: false)
    }

    private func loadTimelineEvents(
        for childID: UUID,
        on day: Date
    ) throws -> [BabyEvent] {
        try eventRepository.loadEvents(
            for: childID,
            on: day,
            calendar: calendar,
            includingDeleted: false
        ).sorted { left, right in
            timelineStartDate(for: left) < timelineStartDate(for: right)
        }
    }

    private func loadTimelinePages(
        for childID: UUID,
        days: [Date]
    ) throws -> [TimelineDayPageState] {
        try days.map { day in
            let events = try loadTimelineEvents(for: childID, on: day)

            return TimelineDayPageState(
                date: day,
                dayTitle: timelineDayTitle(for: day),
                shortWeekdayTitle: shortWeekdayTitle(for: day),
                isToday: calendar.isDateInToday(day),
                blocks: makeTimelineBlocks(from: events, on: day),
                emptyStateTitle: "No events for this day",
                emptyStateMessage: "Try another day or use Quick Log to add the next event."
            )
        }
    }

    private func makeCurrentStateSummary(
        from events: [BabyEvent],
        activeSleep: SleepEvent?
    ) -> CurrentStateSummaryViewState? {
        guard let lastEvent = LastEventSummaryCalculator.makeSummary(from: events) else {
            return nil
        }

        let lastFeed = FeedSummaryCalculator.makeSummary(from: events)
            .map(FeedStatusViewState.init)
        let lastSleep = LastSleepSummaryCalculator.makeSummary(
            from: events,
            activeSleep: activeSleep
        )
        let lastNappy = LastNappySummaryCalculator.makeSummary(from: events)

        return CurrentStateSummaryViewState(
            lastEvent: lastEvent,
            lastFeed: lastFeed,
            lastSleep: lastSleep,
            lastNappy: lastNappy
        )
    }

    private func makeHomeScreenState(
        from events: [BabyEvent],
        activeSleep: SleepEvent?
    ) -> HomeScreenState {
        HomeScreenState(
            currentStateSummary: makeCurrentStateSummary(from: events, activeSleep: activeSleep),
            recentEvents: Array(events.compactMap { EventCardViewState(event: $0) }.prefix(6)),
            emptyStateTitle: "No recent activity",
            emptyStateMessage: "Use Quick Log to add the first event."
        )
    }

    private func makeEventHistoryScreenState(
        from events: [BabyEvent]
    ) -> EventHistoryScreenState {
        let filtered = activeEventFilter.isEmpty
            ? events
            : events.filter { activeEventFilter.matches($0) }
        return EventHistoryScreenState(
            events: filtered.compactMap { EventCardViewState(event: $0) },
            filterIsActive: !activeEventFilter.isEmpty,
            emptyStateTitle: activeEventFilter.isEmpty ? "No events logged yet" : "No matching events",
            emptyStateMessage: activeEventFilter.isEmpty
                ? "Use Quick Log on Home to add the first event."
                : "Try adjusting or clearing your filters."
        )
    }


    private func makeSummaryScreenState(
        from events: [BabyEvent]
    ) -> SummaryScreenState {
        SummaryScreenState(
            events: events,
            emptyStateTitle: "No summary data yet",
            emptyStateMessage: "Add events and your key trends will appear here."
        )
    }

    private func makeFeedLiveActivitySnapshot(
        from events: [BabyEvent],
        child: Child
    ) -> FeedLiveActivitySnapshot? {
        guard let summary = FeedSummaryCalculator.makeSummary(from: events) else {
            return nil
        }

        return FeedLiveActivitySnapshot(
            childID: child.id,
            childName: child.name,
            lastFeedKind: summary.lastFeedKind,
            lastFeedAt: summary.lastFeedAt
        )
    }

    private func eventTitle(for event: BabyEvent) -> String {
        BabyEventPresentation.title(for: event)
    }

    private func startUndoDeleteExpiryTask() {
        undoDeleteTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(10))

            guard !Task.isCancelled else {
                return
            }

            clearUndoDeleteState()
        }
    }

    private func clearUndoDeleteState() {
        undoDeleteTask?.cancel()
        undoDeleteTask = nil
        pendingUndoDeletedEvent = nil
        undoDeleteMessage = nil
    }

    private func resolveErrorMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }

        return "Something went wrong. Please try again."
    }

    private func normalizedTimelineDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func synchronizeTimelineSelection(for childID: UUID) {
        guard timelineChildID != childID else {
            return
        }

        timelineChildID = childID
        timelineSelectedDay = normalizedTimelineDay(for: .now)
        timelineDisplayMode = .day
        activeEventFilter = .empty
    }

    private func makeTimelineScreenState(
        from pages: [TimelineDayPageState],
        selectedDay: Date,
        timelineEvents: [BabyEvent],
        cloudKitStatus: CloudKitStatusViewState
    ) -> TimelineScreenState {
        let today = normalizedTimelineDay(for: .now)
        let selectedPageIndex = pages.firstIndex(where: { page in
            calendar.isDate(page.date, inSameDayAs: selectedDay)
        }) ?? 0
        let stripDataset = buildTimelineStripDatasetUseCase.execute(
            events: timelineEvents,
            calendar: calendar
        )
        let stripColumns = makeTimelineStripColumns(from: stripDataset)
        let selectedStripColumnIndex = stripColumns.firstIndex(where: { column in
            calendar.isDate(column.date, inSameDayAs: selectedDay)
        }) ?? stripDataset.todayIndex

        return TimelineScreenState(
            selectedDay: selectedDay,
            selectedDayTitle: timelineDayTitle(for: selectedDay),
            weekTitle: timelineWeekTitle(for: pages.map(\.date)),
            pages: pages,
            selectedPageIndex: selectedPageIndex,
            showsJumpToToday: selectedDay != today,
            canMoveToNextDay: true,
            syncMessage: timelineSyncMessage(for: cloudKitStatus),
            displayMode: timelineDisplayMode,
            stripColumns: stripColumns,
            selectedStripColumnIndex: selectedStripColumnIndex
        )
    }

    private func makeTimelineStripColumns(
        from dataset: TimelineStripDataset
    ) -> [TimelineStripDayColumnViewState] {
        dataset.columns.map { column in
            TimelineStripDayColumnViewState(
                date: column.date,
                shortWeekdayTitle: shortWeekdayTitle(for: column.date),
                dayNumberTitle: column.date.formatted(.dateTime.day()),
                isToday: calendar.isDateInToday(column.date),
                slots: column.slots.map(\.kind)
            )
        }
    }

    private func makeTimelineBlocks(
        from events: [BabyEvent],
        on selectedDay: Date
    ) -> [TimelineEventBlockViewState] {
        let blocks = events.map { event in
            makeTimelineBlock(from: event, on: selectedDay)
        }

        return assignTimelineLayout(to: blocks)
    }

    private func makeTimelineBlock(
        from event: BabyEvent,
        on selectedDay: Date
    ) -> TimelineEventBlockViewState {
        let startMinute = visibleTimelineStartMinute(for: event, on: selectedDay)
        let endMinute = visibleTimelineEndMinute(for: event, on: selectedDay)

        switch event {
        case let .breastFeed(feed):
            let durationMinutes = max(
                1,
                Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60)
            )

            return TimelineEventBlockViewState(
                id: feed.id,
                kind: .breastFeed,
                title: BabyEventPresentation.title(for: event),
                detailText: BabyEventPresentation.detailText(for: event) ?? "",
                timeText: "\(shortTimeText(for: feed.startedAt))-\(shortTimeText(for: feed.endedAt))",
                compactText: compactTimelineText(for: event),
                startMinute: startMinute,
                endMinute: endMinute,
                laneIndex: 0,
                laneCount: 1,
                actionPayload: .editBreastFeed(
                    durationMinutes: durationMinutes,
                    endTime: feed.endedAt,
                    side: feed.side,
                    leftDurationSeconds: feed.leftDurationSeconds,
                    rightDurationSeconds: feed.rightDurationSeconds
                )
            )
        case let .bottleFeed(feed):
            return TimelineEventBlockViewState(
                id: feed.id,
                kind: .bottleFeed,
                title: BabyEventPresentation.title(for: event),
                detailText: BabyEventPresentation.detailText(for: event) ?? "",
                timeText: shortTimeText(for: feed.metadata.occurredAt),
                compactText: compactTimelineText(for: event),
                startMinute: startMinute,
                endMinute: endMinute,
                laneIndex: 0,
                laneCount: 1,
                actionPayload: .editBottleFeed(
                    amountMilliliters: feed.amountMilliliters,
                    occurredAt: feed.metadata.occurredAt,
                    milkType: feed.milkType
                )
            )
        case let .sleep(sleep):
            if let endedAt = sleep.endedAt {
                return TimelineEventBlockViewState(
                    id: sleep.id,
                    kind: .sleep,
                    title: BabyEventPresentation.title(for: event),
                    detailText: BabyEventPresentation.detailText(for: event) ?? "",
                    timeText: "\(shortTimeText(for: sleep.startedAt))-\(shortTimeText(for: endedAt))",
                    compactText: compactTimelineText(for: event),
                    startMinute: startMinute,
                    endMinute: endMinute,
                    laneIndex: 0,
                    laneCount: 1,
                    actionPayload: .editSleep(
                        startedAt: sleep.startedAt,
                        endedAt: endedAt
                    )
                )
            }

            return TimelineEventBlockViewState(
                id: sleep.id,
                kind: .sleep,
                title: BabyEventPresentation.title(for: event),
                detailText: BabyEventPresentation.detailText(for: event) ?? "",
                timeText: "Started \(shortTimeText(for: sleep.startedAt))",
                compactText: compactTimelineText(for: event),
                startMinute: startMinute,
                endMinute: endMinute,
                laneIndex: 0,
                laneCount: 1,
                actionPayload: .endSleep(startedAt: sleep.startedAt)
            )
        case let .nappy(nappy):
            return TimelineEventBlockViewState(
                id: nappy.id,
                kind: .nappy,
                title: BabyEventPresentation.title(for: event),
                detailText: BabyEventPresentation.detailText(for: event) ?? "",
                timeText: shortTimeText(for: nappy.metadata.occurredAt),
                compactText: compactTimelineText(for: event),
                startMinute: startMinute,
                endMinute: endMinute,
                laneIndex: 0,
                laneCount: 1,
                actionPayload: .editNappy(
                    type: nappy.type,
                    occurredAt: nappy.metadata.occurredAt,
                    peeVolume: nappy.peeVolume,
                    pooVolume: nappy.pooVolume,
                    pooColor: nappy.pooColor
                )
            )
        }
    }

    private func assignTimelineLayout(
        to blocks: [TimelineEventBlockViewState]
    ) -> [TimelineEventBlockViewState] {
        var laneEndMinutes: [Int] = []
        var laneIndexesByID: [UUID: Int] = [:]

        for block in blocks {
            if let laneIndex = laneEndMinutes.firstIndex(where: { block.startMinute >= $0 }) {
                laneEndMinutes[laneIndex] = block.endMinute
                laneIndexesByID[block.id] = laneIndex
            } else {
                laneIndexesByID[block.id] = laneEndMinutes.count
                laneEndMinutes.append(block.endMinute)
            }
        }

        return blocks.map { block in
            let laneIndex = laneIndexesByID[block.id] ?? 0
            let laneCount = timelineLaneCount(for: block, within: blocks)

            return block.updatingLayout(
                laneIndex: laneIndex,
                laneCount: laneCount
            )
        }
    }

    private func timelineLaneCount(
        for block: TimelineEventBlockViewState,
        within blocks: [TimelineEventBlockViewState]
    ) -> Int {
        let candidateMinutes = blocks
            .filter { other in
                other.endMinute > block.startMinute &&
                    other.startMinute < block.endMinute
            }
            .map(\.startMinute) + [block.startMinute]

        return candidateMinutes.reduce(into: 1) { currentMax, minute in
            let concurrentCount = blocks.count { other in
                other.startMinute <= minute && other.endMinute > minute
            }
            currentMax = max(currentMax, concurrentCount)
        }
    }

    private func visibleTimelineStartMinute(
        for event: BabyEvent,
        on selectedDay: Date
    ) -> Int {
        let dayStart = normalizedTimelineDay(for: selectedDay)
        let visibleStart = max(timelineStartDate(for: event), dayStart)

        return minuteOfDay(for: visibleStart, relativeTo: dayStart)
    }

    private func visibleTimelineEndMinute(
        for event: BabyEvent,
        on selectedDay: Date
    ) -> Int {
        let dayStart = normalizedTimelineDay(for: selectedDay)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        let minimumDurationMinutes = 20
        let visibleEnd = min(timelineEndDate(for: event), dayEnd)
        let unclampedMinute = minuteOfDay(for: visibleEnd, relativeTo: dayStart)
        let minimumEndMinute = visibleTimelineStartMinute(for: event, on: selectedDay) + minimumDurationMinutes

        return min(1_440, max(unclampedMinute, minimumEndMinute))
    }

    private func minuteOfDay(
        for date: Date,
        relativeTo dayStart: Date
    ) -> Int {
        let interval = date.timeIntervalSince(dayStart)
        return max(0, min(1_440, Int(interval / 60)))
    }

    private func timelineStartDate(for event: BabyEvent) -> Date {
        switch event {
        case let .breastFeed(feed):
            return feed.startedAt
        case let .bottleFeed(feed):
            return feed.metadata.occurredAt
        case let .sleep(sleep):
            return sleep.startedAt
        case let .nappy(event):
            return event.metadata.occurredAt
        }
    }

    private func timelineEndDate(for event: BabyEvent) -> Date {
        switch event {
        case let .breastFeed(feed):
            return feed.endedAt
        case let .bottleFeed(feed):
            return feed.metadata.occurredAt
        case let .sleep(sleep):
            return sleep.endedAt ?? Date()
        case let .nappy(event):
            return event.metadata.occurredAt
        }
    }

    private func timelineDayTitle(for day: Date) -> String {
        if calendar.isDateInToday(day) {
            return "Today"
        }

        if calendar.isDateInYesterday(day) {
            return "Yesterday"
        }

        return day.formatted(date: .numeric, time: .omitted)
    }

    private func timelineVisibleDays(
        for selectedDay: Date
    ) -> [Date] {
        let normalizedDay = normalizedTimelineDay(for: selectedDay)
        var sundayCalendar = calendar
        sundayCalendar.firstWeekday = 2

        let components = sundayCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: normalizedDay)
        guard let weekStart = sundayCalendar.date(from: components) else {
            return [normalizedDay]
        }

        return (0..<7).compactMap { offset in
            sundayCalendar.date(byAdding: .day, value: offset, to: weekStart).map(normalizedTimelineDay(for:))
        }
    }

    private func shortWeekdayTitle(for day: Date) -> String {
        day.formatted(.dateTime.weekday(.abbreviated))
    }

    private func timelineWeekTitle(for days: [Date]) -> String {
        guard let start = days.first, let end = days.last else {
            return ""
        }

        if calendar.isDate(start, equalTo: end, toGranularity: .month) {
            return "\(start.formatted(.dateTime.month(.abbreviated))) \(start.formatted(.dateTime.day()))-\(end.formatted(.dateTime.day()))"
        }

        return "\(start.formatted(.dateTime.month(.abbreviated).day()))-\(end.formatted(.dateTime.month(.abbreviated).day()))"
    }

    private func timelineSyncMessage(
        for cloudKitStatus: CloudKitStatusViewState
    ) -> String? {
        switch cloudKitStatus.state {
        case .upToDate:
            return nil
        case .pendingSync:
            return "Changes are saved locally and will sync automatically."
        case .syncing, .failed:
            return cloudKitStatus.detailMessage
        }
    }

    private func shortTimeText(for date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func compactTimelineText(for event: BabyEvent) -> String {
        switch event {
        case let .breastFeed(feed):
            let durationMinutes = max(
                1,
                Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60)
            )
            return "\(durationMinutes) min"
        case let .bottleFeed(feed):
            return "\(feed.amountMilliliters) mL"
        case let .sleep(sleep):
            guard let endedAt = sleep.endedAt else {
                return "Sleep"
            }

            let durationMinutes = max(
                1,
                Int(endedAt.timeIntervalSince(sleep.startedAt) / 60)
            )
            return "\(durationMinutes) min"
        case let .nappy(event):
            switch event.type {
            case .dry:
                return "Dry"
            case .wee:
                return "Wee"
            case .poo:
                return "Poo"
            case .mixed:
                return "Mixed"
            }
        }
    }

    // MARK: - CSV Import

    public func parseCSVForImport(data: Data) {
        guard let profile else {
            csvImportState = .error("No active child selected")
            return
        }

        let parseResult = HuckleberryCSVParser().parse(data: data)

        do {
            let taggedEvents = try CheckImportDuplicatesUseCase(eventRepository: eventRepository)
                .execute(.init(events: parseResult.events, childID: profile.child.id))
            csvImportState = .previewing(ImportPreviewState(parseResult: parseResult, taggedEvents: taggedEvents))
        } catch {
            // If duplicate check fails, treat everything as new
            let taggedEvents = parseResult.events.map { TaggedImportEvent(event: $0, duplicateStatus: .new) }
            csvImportState = .previewing(ImportPreviewState(parseResult: parseResult, taggedEvents: taggedEvents))
        }
    }

    public func reportImportFileError(_ message: String) {
        csvImportState = .error(message)
    }

    public func toggleImportEvent(id: UUID) {
        guard case .previewing(var previewState) = csvImportState else { return }
        previewState.toggle(id)
        csvImportState = .previewing(previewState)
    }

    public func skipAllDuplicates() {
        guard case .previewing(var previewState) = csvImportState else { return }
        previewState.skipAllDuplicates()
        csvImportState = .previewing(previewState)
    }

    public func selectAllImportEvents() {
        guard case .previewing(var previewState) = csvImportState else { return }
        previewState.selectAllEvents()
        csvImportState = .previewing(previewState)
    }

    public func confirmImport() {
        guard case .previewing(let previewState) = csvImportState else { return }
        guard let profile, let localUser else {
            csvImportState = .error("No active child selected")
            return
        }

        let eventsToImport = previewState.selectedEvents
        guard !eventsToImport.isEmpty else {
            csvImportState = .error("No events selected to import")
            return
        }

        csvImportState = .importing

        Task { @MainActor in
            do {
                let saveResult = try ImportEventsUseCase(eventRepository: eventRepository)
                    .execute(.init(
                        events: eventsToImport,
                        childID: profile.child.id,
                        localUserID: localUser.id,
                        membership: profile.currentMembership
                    ))
                // Combine parse-level skips with save-level skips in the final result
                let result = CSVImportResult(
                    importedCount: saveResult.importedCount,
                    skippedParseCount: previewState.parseResult.skippedCount,
                    skippedSaveCount: saveResult.skippedSaveCount,
                    skippedReasons: previewState.parseResult.skippedReasons + saveResult.skippedReasons
                )
                csvImportState = .complete(result)
                refresh(selecting: childSelectionStore.loadSelectedChildID())
                _ = await syncEngine.refreshAfterLocalWrite()
                refresh(selecting: childSelectionStore.loadSelectedChildID())
            } catch {
                csvImportState = .error(resolveErrorMessage(for: error))
            }
        }
    }

    public func cancelImport() {
        csvImportState = .idle
    }

    public func dismissImportResult() {
        csvImportState = .idle
    }

    // MARK: - Export

    public func exportData() {
        guard let profile else {
            dataExportState = .error("No active child selected")
            return
        }

        dataExportState = .exporting

        Task { @MainActor in
            do {
                let data = try ExportEventsUseCase(eventRepository: eventRepository)
                    .execute(.init(child: profile.child, membership: profile.currentMembership))

                let childName = profile.child.name
                    .replacingOccurrences(of: " ", with: "-")
                    .filter { $0.isLetter || $0 == "-" }
                let dateStamp = Date().formatted(.iso8601.year().month().day())
                let fileName = "Nest-\(childName)-\(dateStamp).json"

                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try data.write(to: tempURL, options: .atomic)

                dataExportState = .ready(tempURL)
            } catch {
                dataExportState = .error(resolveErrorMessage(for: error))
            }
        }
    }

    public func dismissExport() {
        dataExportState = .idle
    }

    // MARK: - Nest Import

    public func parseNestFileForImport(data: Data) {
        guard let profile else {
            nestImportState = .error("No active child selected")
            return
        }

        let parseResult = NestJSONParser().parse(data: data)

        guard !parseResult.events.isEmpty || parseResult.skippedCount > 0 else {
            nestImportState = .error("The selected file contains no recognisable events")
            return
        }

        do {
            let taggedEvents = try CheckImportDuplicatesUseCase(eventRepository: eventRepository)
                .execute(.init(events: parseResult.events, childID: profile.child.id))
            nestImportState = .previewing(ImportPreviewState(parseResult: parseResult, taggedEvents: taggedEvents))
        } catch {
            let taggedEvents = parseResult.events.map { TaggedImportEvent(event: $0, duplicateStatus: .new) }
            nestImportState = .previewing(ImportPreviewState(parseResult: parseResult, taggedEvents: taggedEvents))
        }
    }

    public func reportNestImportFileError(_ message: String) {
        nestImportState = .error(message)
    }

    public func toggleNestImportEvent(id: UUID) {
        guard case .previewing(var previewState) = nestImportState else { return }
        previewState.toggle(id)
        nestImportState = .previewing(previewState)
    }

    public func skipAllNestDuplicates() {
        guard case .previewing(var previewState) = nestImportState else { return }
        previewState.skipAllDuplicates()
        nestImportState = .previewing(previewState)
    }

    public func selectAllNestImportEvents() {
        guard case .previewing(var previewState) = nestImportState else { return }
        previewState.selectAllEvents()
        nestImportState = .previewing(previewState)
    }

    public func confirmNestImport() {
        guard case .previewing(let previewState) = nestImportState else { return }
        guard let profile, let localUser else {
            nestImportState = .error("No active child selected")
            return
        }

        let eventsToImport = previewState.selectedEvents
        guard !eventsToImport.isEmpty else {
            nestImportState = .error("No events selected to import")
            return
        }

        nestImportState = .importing

        Task { @MainActor in
            do {
                let saveResult = try ImportEventsUseCase(eventRepository: eventRepository)
                    .execute(.init(
                        events: eventsToImport,
                        childID: profile.child.id,
                        localUserID: localUser.id,
                        membership: profile.currentMembership
                    ))
                let result = CSVImportResult(
                    importedCount: saveResult.importedCount,
                    skippedParseCount: previewState.parseResult.skippedCount,
                    skippedSaveCount: saveResult.skippedSaveCount,
                    skippedReasons: previewState.parseResult.skippedReasons + saveResult.skippedReasons
                )
                nestImportState = .complete(result)
                refresh(selecting: childSelectionStore.loadSelectedChildID())
                _ = await syncEngine.refreshAfterLocalWrite()
                refresh(selecting: childSelectionStore.loadSelectedChildID())
            } catch {
                nestImportState = .error(resolveErrorMessage(for: error))
            }
        }
    }

    public func cancelNestImport() {
        nestImportState = .idle
    }

    public func dismissNestImportResult() {
        nestImportState = .idle
    }
}
