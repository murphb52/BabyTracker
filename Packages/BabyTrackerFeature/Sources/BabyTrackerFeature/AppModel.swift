import BabyTrackerDomain
import BabyTrackerPersistence
import BabyTrackerSync
import Foundation
import Observation

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

    private let repository: ChildProfileRepository
    private let eventRepository: EventRepository
    private let syncEngine: CloudKitSyncEngine
    private let liveActivityManager: any FeedLiveActivityManaging
    private let calendar = Calendar.autoupdatingCurrent
    private var timelineSelectedDay = Calendar.autoupdatingCurrent.startOfDay(for: .now)
    private var timelineChildID: UUID?
    private var pendingUndoDeletedEvent: BabyEvent?
    private var undoDeleteTask: Task<Void, Never>?

    public init(
        repository: ChildProfileRepository,
        eventRepository: EventRepository,
        syncEngine: CloudKitSyncEngine,
        liveActivityManager: any FeedLiveActivityManaging = NoOpFeedLiveActivityManager()
    ) {
        self.repository = repository
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
            refresh(selecting: repository.loadSelectedChildID())
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
            refresh(selecting: repository.loadSelectedChildID())
        }
    }

    public func refreshSyncStatus() {
        Task { @MainActor in
            _ = await syncEngine.refreshForeground()
            refresh(selecting: repository.loadSelectedChildID())
        }
    }

    public func createLocalUser(displayName: String) {
        perform {
            let user = try UserIdentity(displayName: displayName)
            try repository.saveLocalUser(user)
        }
    }

    public func createChild(name: String, birthDate: Date?) {
        perform {
            guard let localUser else { return }

            let child = try Child(
                name: name,
                birthDate: birthDate,
                createdBy: localUser.id
            )
            let ownerMembership = Membership.owner(
                childID: child.id,
                userID: localUser.id,
                createdAt: child.createdAt
            )

            try repository.saveChild(child)
            try repository.saveMembership(ownerMembership)
            repository.saveSelectedChildID(child.id)
        }
    }

    public func updateCurrentChild(name: String, birthDate: Date?) {
        perform {
            guard let profile else { return }
            guard profile.canEditChild else {
                throw ChildProfileValidationError.insufficientPermissions
            }

            let updatedChild = try profile.child.updating(name: name, birthDate: birthDate)
            try repository.saveChild(updatedChild)
        }
    }

    public func archiveCurrentChild() {
        perform {
            guard let profile else { return }
            guard profile.canArchiveChild else {
                throw ChildProfileValidationError.insufficientPermissions
            }

            var archivedChild = profile.child
            archivedChild.isArchived = true
            try repository.saveChild(archivedChild)

            if repository.loadSelectedChildID() == archivedChild.id {
                repository.saveSelectedChildID(nil)
            }
        }
    }

    public func restoreChild(id: UUID) {
        perform {
            guard var restoredChild = try repository.loadChild(id: id) else { return }
            restoredChild.isArchived = false
            try repository.saveChild(restoredChild)
            repository.saveSelectedChildID(id)
        }
    }

    public func selectChild(id: UUID) {
        repository.saveSelectedChildID(id)
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
        refresh(selecting: repository.loadSelectedChildID())
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
        refresh(selecting: repository.loadSelectedChildID())
    }

    public func jumpTimelineToToday() {
        timelineSelectedDay = normalizedTimelineDay(for: .now)
        refresh(selecting: repository.loadSelectedChildID())
    }

    public func showTimelineDay(_ day: Date) {
        timelineSelectedDay = normalizedTimelineDay(for: day)
        refresh(selecting: repository.loadSelectedChildID())
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
                refresh(selecting: repository.loadSelectedChildID())
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
            guard profile.canManageSharing else {
                throw ChildProfileValidationError.insufficientPermissions
            }

            let candidateMemberships = profile.activeCaregivers.map(\.membership) +
                profile.removedCaregivers.map(\.membership) +
                (profile.owner.map { [$0.membership] } ?? [])

            guard let membership = candidateMemberships.first(where: { $0.id == membershipID }) else {
                return
            }

            try MembershipValidator.validateRemoval(
                of: membership,
                within: candidateMemberships
            )
            let removedMembership = try membership.removed()
            try repository.saveMembership(removedMembership)

            Task { @MainActor in
                try? await syncEngine.removeParticipant(membership: removedMembership)
                refresh(selecting: repository.loadSelectedChildID())
            }
        }
    }

    public func leaveChildShare() {
        guard let profile, profile.canLeaveShare else { return }
        let childID = profile.child.id
        Task { @MainActor in
            do {
                try await syncEngine.leaveShare(childID: childID)
                try repository.purgeChildData(id: childID)
            } catch {
                errorMessage = resolveErrorMessage(for: error)
            }
            refresh(selecting: repository.loadSelectedChildID())
        }
    }

    @discardableResult
    public func logBreastFeed(
        durationMinutes: Int,
        endTime: Date,
        side: BreastSide?
    ) -> Bool {
        perform {
            guard let profile else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let localUser else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard profile.canLogEvents else {
                throw ChildProfileValidationError.insufficientPermissions
            }

            let startedAt = endTime.addingTimeInterval(TimeInterval(durationMinutes * -60))
            let event = try BreastFeedEvent(
                metadata: EventMetadata(
                    childID: profile.child.id,
                    occurredAt: endTime,
                    createdAt: .now,
                    createdBy: localUser.id
                ),
                side: side,
                startedAt: startedAt,
                endedAt: endTime
            )

            try eventRepository.saveEvent(.breastFeed(event))
        }
    }

    @discardableResult
    public func logBottleFeed(
        amountMilliliters: Int,
        occurredAt: Date,
        milkType: MilkType?
    ) -> Bool {
        perform {
            guard let profile else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let localUser else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard profile.canLogEvents else {
                throw ChildProfileValidationError.insufficientPermissions
            }

            let event = try BottleFeedEvent(
                metadata: EventMetadata(
                    childID: profile.child.id,
                    occurredAt: occurredAt,
                    createdAt: .now,
                    createdBy: localUser.id
                ),
                amountMilliliters: amountMilliliters,
                milkType: milkType
            )

            try eventRepository.saveEvent(.bottleFeed(event))
        }
    }

    @discardableResult
    public func logNappy(
        type: NappyType,
        occurredAt: Date,
        intensity: NappyIntensity?,
        pooColor: PooColor?
    ) -> Bool {
        perform {
            guard let profile else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let localUser else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard profile.canLogEvents else {
                throw ChildProfileValidationError.insufficientPermissions
            }

            let event = try NappyEvent(
                metadata: EventMetadata(
                    childID: profile.child.id,
                    occurredAt: occurredAt,
                    createdAt: .now,
                    createdBy: localUser.id
                ),
                type: type,
                intensity: intensity,
                pooColor: pooColor
            )

            try eventRepository.saveEvent(.nappy(event))
        }
    }

    @discardableResult
    public func startSleep(startedAt: Date) -> Bool {
        perform {
            guard let profile else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let localUser else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard profile.canLogEvents else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard try eventRepository.loadActiveSleepEvent(for: profile.child.id) == nil else {
                throw BabyEventError.activeSleepAlreadyInProgress
            }

            let event = try SleepEvent(
                metadata: EventMetadata(
                    childID: profile.child.id,
                    occurredAt: startedAt,
                    createdAt: .now,
                    createdBy: localUser.id
                ),
                startedAt: startedAt,
                endedAt: nil
            )

            try eventRepository.saveEvent(.sleep(event))
        }
    }

    @discardableResult
    public func endSleep(
        id: UUID,
        startedAt: Date,
        endedAt: Date
    ) -> Bool {
        perform {
            guard let profile else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let localUser else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard profile.canLogEvents else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let event = try eventRepository.loadEvent(id: id) else {
                throw BabyEventError.noActiveSleepInProgress
            }
            guard case let .sleep(sleepEvent) = event, sleepEvent.endedAt == nil else {
                throw BabyEventError.noActiveSleepInProgress
            }

            let updatedEvent = try sleepEvent.updating(
                startedAt: startedAt,
                endedAt: endedAt,
                updatedBy: localUser.id
            )
            try eventRepository.saveEvent(.sleep(updatedEvent))
        }
    }

    @discardableResult
    public func updateBreastFeed(
        id: UUID,
        durationMinutes: Int,
        endTime: Date,
        side: BreastSide?
    ) -> Bool {
        perform {
            guard let profile else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let localUser else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard profile.canManageEvents else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let event = try eventRepository.loadEvent(id: id) else {
                return
            }
            guard case let .breastFeed(feed) = event else {
                return
            }

            let updatedEvent = try feed.updating(
                durationMinutes: durationMinutes,
                endTime: endTime,
                side: side,
                updatedBy: localUser.id
            )
            try eventRepository.saveEvent(.breastFeed(updatedEvent))
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
            guard let profile else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let localUser else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard profile.canManageEvents else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let event = try eventRepository.loadEvent(id: id) else {
                return
            }
            guard case let .bottleFeed(feed) = event else {
                return
            }

            let updatedEvent = try feed.updating(
                amountMilliliters: amountMilliliters,
                occurredAt: occurredAt,
                milkType: milkType,
                updatedBy: localUser.id
            )
            try eventRepository.saveEvent(.bottleFeed(updatedEvent))
        }
    }

    @discardableResult
    public func updateNappy(
        id: UUID,
        type: NappyType,
        occurredAt: Date,
        intensity: NappyIntensity?,
        pooColor: PooColor?
    ) -> Bool {
        perform {
            guard let profile else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let localUser else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard profile.canManageEvents else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let event = try eventRepository.loadEvent(id: id) else {
                return
            }
            guard case let .nappy(nappyEvent) = event else {
                return
            }

            let updatedEvent = try nappyEvent.updating(
                type: type,
                occurredAt: occurredAt,
                intensity: intensity,
                pooColor: pooColor,
                updatedBy: localUser.id
            )
            try eventRepository.saveEvent(.nappy(updatedEvent))
        }
    }

    @discardableResult
    public func updateSleep(
        id: UUID,
        startedAt: Date,
        endedAt: Date
    ) -> Bool {
        perform {
            guard let profile else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let localUser else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard profile.canManageEvents else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let event = try eventRepository.loadEvent(id: id) else {
                return
            }
            guard case let .sleep(sleepEvent) = event, sleepEvent.endedAt != nil else {
                return
            }

            let updatedEvent = try sleepEvent.updating(
                startedAt: startedAt,
                endedAt: endedAt,
                updatedBy: localUser.id
            )
            try eventRepository.saveEvent(.sleep(updatedEvent))
        }
    }

    @discardableResult
    public func deleteEvent(id: UUID) -> Bool {
        perform {
            guard let profile else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let localUser else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard profile.canManageEvents else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let event = try eventRepository.loadEvent(id: id) else {
                return
            }

            clearUndoDeleteState()
            try eventRepository.softDeleteEvent(
                id: id,
                deletedAt: .now,
                deletedBy: localUser.id
            )
            pendingUndoDeletedEvent = event
            undoDeleteMessage = "\(eventTitle(for: event)) deleted"
            startUndoDeleteExpiryTask()
        }
    }

    public func undoLastDeletedEvent() {
        perform {
            guard let localUser else {
                throw ChildProfileValidationError.insufficientPermissions
            }
            guard let pendingUndoDeletedEvent else {
                return
            }

            let restoredEvent = restoreDeletedEvent(
                pendingUndoDeletedEvent,
                restoredBy: localUser.id
            )
            try eventRepository.saveEvent(restoredEvent)
            clearUndoDeleteState()
        }
    }

    @discardableResult
    private func perform(_ operation: () throws -> Void) -> Bool {
        do {
            try operation()
            refresh(selecting: repository.loadSelectedChildID())
            Task { @MainActor in
                _ = await syncEngine.refreshAfterLocalWrite()
                refresh(selecting: repository.loadSelectedChildID())
            }
            return true
        } catch {
            errorMessage = resolveErrorMessage(for: error)
            refresh(selecting: repository.loadSelectedChildID())
            return false
        }
    }

    private func refresh(selecting selectedChildID: UUID?) {
        do {
            localUser = try repository.loadLocalUser()

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
                children: repository.loadActiveChildren(for: localUser.id),
                userID: localUser.id
            )
            archivedChildren = try loadChildSummaries(
                children: repository.loadArchivedChildren(for: localUser.id),
                userID: localUser.id
            )

            guard !activeChildren.isEmpty else {
                route = .noChildren
                profile = nil
                timelineChildID = nil
                liveActivityManager.synchronize(with: nil)
                return
            }

            let effectiveSelectedChildID = selectedChildID ?? repository.loadSelectedChildID()
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
            repository.saveSelectedChildID(currentSummary.child.id)
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
            let memberships = try repository.loadMemberships(for: child.id)
            guard let membership = memberships.first(where: { membership in
                membership.userID == userID && membership.status == .active
            }) else {
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
        let memberships = try repository.loadMemberships(for: child.id)
        let userIDs = memberships.map(\.userID)
        let users = try repository.loadUsers(for: userIDs)
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
                cloudKitStatus: cloudKitStatus
            ),
            cloudKitStatus: cloudKitStatus,
            canShareChild: ChildAccessPolicy.canPerform(.inviteCaregiver, membership: currentMembership) &&
                syncEngine.statusSummary.state != .failed
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
        EventHistoryScreenState(
            events: events.compactMap { EventCardViewState(event: $0) },
            emptyStateTitle: "No events logged yet",
            emptyStateMessage: "Use Quick Log on Home to add the first event."
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

    private func restoreDeletedEvent(
        _ event: BabyEvent,
        restoredBy userID: UUID
    ) -> BabyEvent {
        switch event {
        case var .breastFeed(feed):
            feed.metadata.restoreDeleted(by: userID)
            return .breastFeed(feed)
        case var .bottleFeed(feed):
            feed.metadata.restoreDeleted(by: userID)
            return .bottleFeed(feed)
        case var .sleep(feed):
            feed.metadata.restoreDeleted(by: userID)
            return .sleep(feed)
        case var .nappy(feed):
            feed.metadata.restoreDeleted(by: userID)
            return .nappy(feed)
        }
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
    }

    private func makeTimelineScreenState(
        from pages: [TimelineDayPageState],
        selectedDay: Date,
        cloudKitStatus: CloudKitStatusViewState
    ) -> TimelineScreenState {
        let today = normalizedTimelineDay(for: .now)
        let selectedPageIndex = pages.firstIndex(where: { page in
            calendar.isDate(page.date, inSameDayAs: selectedDay)
        }) ?? 0

        return TimelineScreenState(
            selectedDay: selectedDay,
            selectedDayTitle: timelineDayTitle(for: selectedDay),
            weekTitle: timelineWeekTitle(for: pages.map(\.date)),
            pages: pages,
            selectedPageIndex: selectedPageIndex,
            showsJumpToToday: selectedDay != today,
            canMoveToNextDay: true,
            syncMessage: timelineSyncMessage(for: cloudKitStatus)
        )
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
                    side: feed.side
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
                    intensity: nappy.intensity,
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
}
