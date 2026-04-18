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
    public private(set) var errorMessage: String?
    public private(set) var undoDeleteMessage: String?
    public private(set) var isLiveActivityEnabled: Bool
    public private(set) var isReminderNotificationsEnabled: Bool
    public private(set) var transientMessage: String?
    public private(set) var navigationResetToken: Int = 0
    public private(set) var shareAcceptanceLoadingState: ShareAcceptanceLoadingState?
    public private(set) var sleepSheetRequestToken: Int = 0
    public var selectedWorkspaceTab: ChildWorkspaceTab = .home
    public var shareSheetState: ShareSheetState?
    public private(set) var csvImportState: CSVImportState = .idle
    public private(set) var nestImportState: NestImportState = .idle
    public private(set) var dataExportState: DataExportState = .idle
    public private(set) var syncBannerState: SyncBannerState?

    // MARK: - Flat profile data (replaces ChildProfileScreenState)

    /// All visible events for the currently selected child.
    public private(set) var events: [BabyEvent] = []
    /// The currently selected child.
    public private(set) var currentChild: Child?
    /// The local user's active membership for the current child.
    public private(set) var currentMembership: Membership?
    /// Currently running sleep session, if any.
    public private(set) var activeSleep: SleepEvent?
    /// Pre-built timeline day pages for the visible week.
    public private(set) var timelinePages: [TimelineDayGridPageState] = []
    /// Pre-built strip columns for the weekly overview.
    public private(set) var timelineStripColumns: [TimelineStripDayColumnViewState] = []
    /// Latest CloudKit sync status.
    public private(set) var cloudKitStatus: CloudKitStatusViewState = CloudKitStatusViewState(summary: SyncStatusSummary())
    /// All memberships for the current child (used by ChildProfileViewModel).
    public private(set) var memberships: [Membership] = []
    /// Users associated with each membership.
    public private(set) var membershipUsers: [UserIdentity] = []
    /// Pending CloudKit changes awaiting upload.
    public private(set) var pendingChanges: [PendingChangeSummaryItem] = []
    /// Pending share invites for the current child.
    public private(set) var pendingShareInvites: [PendingShareInviteViewState] = []
    /// The day currently visible in the timeline.
    public private(set) var timelineSelectedDay: Date = Calendar.autoupdatingCurrent.startOfDay(for: .now)
    /// The current timeline display mode (day vs. week).
    public private(set) var timelineDisplayMode: TimelineDisplayMode = .day
    /// The active event filter for the event history screen.
    public private(set) var activeEventFilter: EventFilter = .empty

    private let logger = Logger(subsystem: "com.adappt.BabyTracker", category: "AppModel")
    private let childRepository: any ChildRepository
    private let userIdentityRepository: any UserIdentityRepository
    private let membershipRepository: any MembershipRepository
    private let childSelectionStore: any ChildSelectionStore
    private let eventRepository: EventRepository
    private let syncEngine: any CloudKitSyncControlling
    private let liveActivityManager: any FeedLiveActivityManaging
    private let liveActivitySnapshotCache: any FeedLiveActivitySnapshotCaching
    private let liveActivityPreferenceStore: any LiveActivityPreferenceStore
    private let reminderNotificationPreferenceStore: any ReminderNotificationPreferenceStore
    private let localNotificationManager: any LocalNotificationManaging
    private let hapticFeedbackProvider: any HapticFeedbackProviding
    private let appReviewPromptStateStore: any AppReviewPromptStateStoring
    private let appReviewRequester: any AppReviewRequesting
    private let buildTimelineStripDatasetUseCase = BuildTimelineStripDatasetUseCase()
    private let buildTimelineDayGridDatasetUseCase = BuildTimelineDayGridDatasetUseCase()
    private let buildRemoteNotificationUseCase = BuildRemoteCaregiverNotificationUseCase()
    private let calendar = Calendar.autoupdatingCurrent
    private var storedReminderNotificationsEnabled: Bool
    private var hasReminderNotificationPermission: Bool
    private var timelineChildID: UUID?
    private var pendingUndoDeletedEvent: BabyEvent?
    private var undoDeleteTask: Task<Void, Never>?
    private var syncIndicatorDismissTask: Task<Void, Never>?
    private var transientMessageDismissTask: Task<Void, Never>?

    public init(
        childRepository: any ChildRepository,
        userIdentityRepository: any UserIdentityRepository,
        membershipRepository: any MembershipRepository,
        childSelectionStore: any ChildSelectionStore,
        eventRepository: EventRepository,
        syncEngine: any CloudKitSyncControlling,
        liveActivityManager: any FeedLiveActivityManaging = NoOpFeedLiveActivityManager(),
        liveActivitySnapshotCache: any FeedLiveActivitySnapshotCaching = InMemoryFeedLiveActivitySnapshotCache(),
        liveActivityPreferenceStore: any LiveActivityPreferenceStore = InMemoryLiveActivityPreferenceStore(),
        reminderNotificationPreferenceStore: any ReminderNotificationPreferenceStore = InMemoryReminderNotificationPreferenceStore(),
        localNotificationManager: any LocalNotificationManaging = NoOpLocalNotificationManager(),
        hapticFeedbackProvider: any HapticFeedbackProviding = NoOpHapticFeedbackProvider(),
        appReviewPromptStateStore: any AppReviewPromptStateStoring = NoOpAppReviewPromptStateStore(),
        appReviewRequester: any AppReviewRequesting = NoOpAppReviewRequester()
    ) {
        self.childRepository = childRepository
        self.userIdentityRepository = userIdentityRepository
        self.membershipRepository = membershipRepository
        self.childSelectionStore = childSelectionStore
        self.eventRepository = eventRepository
        self.syncEngine = syncEngine
        self.liveActivityManager = liveActivityManager
        self.liveActivitySnapshotCache = liveActivitySnapshotCache
        self.liveActivityPreferenceStore = liveActivityPreferenceStore
        self.reminderNotificationPreferenceStore = reminderNotificationPreferenceStore
        self.localNotificationManager = localNotificationManager
        self.hapticFeedbackProvider = hapticFeedbackProvider
        self.appReviewPromptStateStore = appReviewPromptStateStore
        self.appReviewRequester = appReviewRequester
        self.isLiveActivityEnabled = liveActivityPreferenceStore.isLiveActivityEnabled
        self.storedReminderNotificationsEnabled = reminderNotificationPreferenceStore.isReminderNotificationsEnabled
        self.hasReminderNotificationPermission = true
        self.isReminderNotificationsEnabled = self.storedReminderNotificationsEnabled
    }

    public func load(performLaunchSync: Bool = true) {
        refresh(selecting: nil)
        rescheduleAllDriftNotifications()
        Task { @MainActor in
            await refreshReminderNotificationAuthorization()
        }

        guard performLaunchSync else {
            return
        }

        Task { @MainActor in
            await runSyncRefresh { await self.syncEngine.prepareForLaunch() }
        }
    }

    public func dismissError() {
        errorMessage = nil
    }

    public func dismissShareSheet() {
        shareSheetState = nil
    }

    public func beginAcceptingSharedChild(childName: String?) {
        errorMessage = nil
        shareAcceptanceLoadingState = .syncing(childName: childName)
    }

    public func completeAcceptingSharedChild(childName: String?) {
        load(performLaunchSync: false)
        let resolvedChildName = currentChild?.name ?? childName
        shareAcceptanceLoadingState = .completed(childName: resolvedChildName)
    }

    public func continueAfterAcceptingSharedChild() {
        shareAcceptanceLoadingState = nil
        refresh(selecting: currentChild?.id ?? childSelectionStore.loadSelectedChildID())
        resetNavigationStack()
    }

    public func failAcceptingSharedChild(_ error: Error) {
        shareAcceptanceLoadingState = nil
        AppLogger.shared.log(.error, category: "CloudKitShare", "Failed to accept shared child: \(error)")
        setErrorMessage("Couldn't accept the shared child. \(resolveErrorMessage(for: error))")
    }

    public func requestSleepSheetPresentation() {
        sleepSheetRequestToken &+= 1
    }

    public func setLiveActivitiesEnabled(_ isEnabled: Bool) {
        guard isLiveActivityEnabled != isEnabled else {
            return
        }

        isLiveActivityEnabled = isEnabled
        liveActivityPreferenceStore.setLiveActivityEnabled(isEnabled)

        if isEnabled {
            refresh(selecting: childSelectionStore.loadSelectedChildID())
        } else {
            stopLiveActivity()
        }
    }

    @discardableResult
    public func setReminderNotificationsEnabled(_ isEnabled: Bool) async -> Bool {
        if storedReminderNotificationsEnabled == isEnabled {
            await refreshReminderNotificationAuthorization()
            return isReminderNotificationsEnabled == isEnabled
        }

        if isEnabled {
            let isAuthorized = await localNotificationManager.requestAuthorizationIfNeeded()
            hasReminderNotificationPermission = isAuthorized
            guard isAuthorized else {
                isReminderNotificationsEnabled = false
                return false
            }
        }

        storedReminderNotificationsEnabled = isEnabled
        reminderNotificationPreferenceStore.setReminderNotificationsEnabled(isEnabled)
        let isAuthorized = await localNotificationManager.isAuthorizedForNotifications()
        hasReminderNotificationPermission = isAuthorized
        isReminderNotificationsEnabled = storedReminderNotificationsEnabled && hasReminderNotificationPermission

        if isEnabled {
            await rescheduleAllDriftNotificationsAsync()
        } else {
            await cancelAllDriftNotificationsAsync()
        }
        return isReminderNotificationsEnabled == isEnabled
    }

    public func refreshReminderNotificationAuthorization() async {
        let isAuthorized = await localNotificationManager.isAuthorizedForNotifications()
        let previousValue = isReminderNotificationsEnabled

        hasReminderNotificationPermission = isAuthorized
        isReminderNotificationsEnabled = storedReminderNotificationsEnabled && hasReminderNotificationPermission

        guard previousValue != isReminderNotificationsEnabled else {
            return
        }

        if isReminderNotificationsEnabled {
            await rescheduleAllDriftNotificationsAsync()
        } else {
            await cancelAllDriftNotificationsAsync()
        }
    }

    public func refreshAfterShareSheet() {
        Task { @MainActor in
            await runSyncRefresh { await self.syncEngine.refreshForeground() }
        }
    }

    public func handleShareSheetSaveFailure(_ error: Error) {
        AppLogger.shared.log(
            .error,
            category: "CloudKitShare",
            "Failed to save iCloud share: \(error.localizedDescription)"
        )
        shareSheetState = nil
        setErrorMessage("Couldn't save the iCloud share. \(resolveErrorMessage(for: error))")
    }

    public func refreshSyncStatus() async {
        await runSyncRefresh { await self.syncEngine.refreshForeground() }
    }

    public func forceFullSyncRefresh() async {
        await runSyncRefresh { await self.syncEngine.forceFullRefresh() }
    }

    public func refreshAfterRemoteNotification() async -> SyncStatusSummary {
        let summary = await syncEngine.refreshAfterRemoteNotification()
        await scheduleRemoteSyncNotificationIfNeeded()
        refresh(selecting: childSelectionStore.loadSelectedChildID())
        return summary
    }

    public func requestNotificationAuthorizationIfNeeded() {
        Task { @MainActor in
            _ = await localNotificationManager.requestAuthorizationIfNeeded()
        }
    }

    public func fetchPendingDriftNotifications() async -> [PendingDriftNotification] {
        await localNotificationManager.pendingDriftNotifications()
    }

    public func hardDeleteCurrentChild() {
        guard let currentChild, let currentMembership else { return }
        let childID = currentChild.id
        let childName = currentChild.name
        let intent: HardDeleteChildIntent
        do {
            intent = try HardDeleteChildUseCase()
                .execute(.init(membership: currentMembership))
        } catch {
            errorMessage = resolveErrorMessage(for: error)
            return
        }
        Task { @MainActor in
            var cloudDeleteError: Error?

            do {
                switch intent {
                case .deleteOwnedZone:
                    try await syncEngine.hardDeleteChildCloudData(childID: childID)
                case .leaveCaregiverShare:
                    try await syncEngine.leaveShare(childID: childID)
                }
            } catch {
                cloudDeleteError = error
                AppLogger.shared.log(.error, category: "CloudKitSync", "Hard delete cloud cleanup failed for child \(childID): \(error.localizedDescription)")
            }

            do {
                try childRepository.purgeChildData(id: childID)
                let nextSelectedChildID = try nextSelectedChildID(afterDeleting: childID)
                childSelectionStore.saveSelectedChildID(nextSelectedChildID)
                clearUndoDeleteState()
                showTransientMessage("\(childName) deleted")
                resetNavigationStack()
                refresh(selecting: nextSelectedChildID)
                if let cloudDeleteError {
                    errorMessage = "Local data was cleared, but iCloud cleanup failed: \(cloudDeleteError.localizedDescription)"
                }
            } catch {
                errorMessage = resolveErrorMessage(for: error)
                refresh(selecting: nil)
            }
        }
    }

    public func showOnboarding() {
        route = .identityOnboarding
    }

    public func dismissOnboarding() {
        refresh(selecting: currentChild?.id)
    }

    public func nukeAllData() {
        guard let localUser else { return }
        Task { @MainActor in
            let intent: NukeAllDataIntent
            do {
                intent = try NukeAllDataUseCase(
                    childRepository: childRepository,
                    membershipRepository: membershipRepository
                ).execute(.init(localUserID: localUser.id))
            } catch {
                AppLogger.shared.log(.error, category: "CloudKitSync", "Nuke: failed to resolve intent: \(error)")
                errorMessage = resolveErrorMessage(for: error)
                return
            }

            for childID in intent.caregiverChildIDs {
                do {
                    try await syncEngine.leaveShare(childID: childID)
                } catch {
                    AppLogger.shared.log(.error, category: "CloudKitSync", "Nuke: failed to leave share for child \(childID): \(error.localizedDescription)")
                }
            }
            for childID in intent.ownedChildIDs {
                do {
                    try await syncEngine.hardDeleteChildCloudData(childID: childID)
                } catch {
                    AppLogger.shared.log(.error, category: "CloudKitSync", "Nuke: failed to delete zone for child \(childID): \(error.localizedDescription)")
                }
            }

            do {
                try userIdentityRepository.resetAllData()
                childSelectionStore.saveSelectedChildID(nil)
                clearUndoDeleteState()
                refresh(selecting: nil)
                playHaptic(.destructiveActionConfirmed)
            } catch {
                AppLogger.shared.log(.error, category: "CloudKitSync", "Nuke: failed to reset local data: \(error)")
                setErrorMessage(resolveErrorMessage(for: error))
                refresh(selecting: nil)
            }
        }
    }

    public func createLocalUser(displayName: String) {
        perform {
            _ = try CreateLocalUserUseCase(
                userIdentityRepository: userIdentityRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(displayName: displayName))
        }
    }

    @discardableResult
    public func updateLocalUserName(displayName: String) -> Bool {
        perform {
            _ = try UpdateLocalUserUseCase(
                userIdentityRepository: userIdentityRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
            .execute(.init(displayName: displayName))
        }
    }

    public func createChild(name: String, birthDate: Date?, imageData: Data? = nil) {
        let succeeded = perform {
            guard let localUser else { return }
            _ = try CreateChildUseCase(
                childRepository: childRepository,
                membershipRepository: membershipRepository,
                childSelectionStore: childSelectionStore,
                hapticFeedbackProvider: hapticFeedbackProvider
            ).execute(.init(name: name, birthDate: birthDate, localUser: localUser, imageData: imageData))
        }
        if succeeded { resetNavigationStack() }
    }

    public func updateCurrentChild(
        name: String,
        birthDate: Date?,
        imageData: Data? = nil,
        preferredFeedVolumeUnit: FeedVolumeUnit? = nil
    ) {
        perform {
            guard let currentChild, let currentMembership else { return }
            _ = try UpdateCurrentChildUseCase(
                childRepository: childRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    child: currentChild,
                    name: name,
                    birthDate: birthDate,
                    membership: currentMembership,
                    imageData: imageData,
                    preferredFeedVolumeUnit: preferredFeedVolumeUnit ?? currentChild.preferredFeedVolumeUnit
                ))
        }
    }

    public func archiveCurrentChild() {
        let succeeded = perform {
            guard let currentChild, let currentMembership else { return }
            let revokedCaregivers = try ArchiveChildUseCase(
                childRepository: childRepository,
                membershipRepository: membershipRepository,
                childSelectionStore: childSelectionStore,
                hapticFeedbackProvider: hapticFeedbackProvider
            ).execute(.init(
                child: currentChild,
                membership: currentMembership,
                currentSelectedChildID: childSelectionStore.loadSelectedChildID()
            ))
            for membership in revokedCaregivers {
                Task { @MainActor in
                    try? await syncEngine.removeParticipant(membership: membership)
                }
            }
        }
        if succeeded { resetNavigationStack() }
    }

    public func restoreChild(id: UUID) {
        perform {
            _ = try RestoreChildUseCase(
                childRepository: childRepository,
                childSelectionStore: childSelectionStore,
                hapticFeedbackProvider: hapticFeedbackProvider
            ).execute(.init(childID: id))
        }
    }

    public func selectChild(id: UUID) {
        let currentSelectedChildID = childSelectionStore.loadSelectedChildID()
        let didChangeChild = currentSelectedChildID != id

        childSelectionStore.saveSelectedChildID(id)
        timelineChildID = id
        timelineSelectedDay = normalizedTimelineDay(for: .now)
        if didChangeChild {
            timelineDisplayMode = .day
            activeEventFilter = .empty
            selectedWorkspaceTab = .profile
            resetNavigationStack()
            showTransientMessage("Child changed.")
        }
        refresh(selecting: id)
        playHaptic(.selectionChanged)
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
        playHaptic(.selectionChanged)
    }

    public var eventFilter: EventFilter { activeEventFilter }

    public func updateEventFilter(_ filter: EventFilter) {
        activeEventFilter = filter
        refresh(selecting: childSelectionStore.loadSelectedChildID())
        playHaptic(.selectionChanged)
    }

    public func showChildPicker() {
        guard activeChildren.count > 1 else {
            return
        }

        route = .childPicker
    }

    public func presentShareSheet() {
        guard let currentChild, let currentMembership,
              ChildAccessPolicy.canPerform(.inviteCaregiver, membership: currentMembership),
              syncEngine.statusSummary.state != .failed else {
            return
        }

        Task { @MainActor in
            do {
                let presentation = try await syncEngine.prepareShare(
                    for: currentChild.id
                )
                shareSheetState = ShareSheetState(presentation: presentation)
                refresh(selecting: childSelectionStore.loadSelectedChildID())
                playHaptic(.actionSucceeded)
            } catch {
                AppLogger.shared.log(.error, category: "CloudKitShare", "prepareShare failed: \(error)")
                setErrorMessage(resolveErrorMessage(for: error))
            }
        }
    }

    public func removeCaregiver(membershipID: UUID) {
        guard let currentChild, let currentMembership else {
            return
        }

        perform {
            let removedMembership = try RemoveCaregiverUseCase(
                membershipRepository: membershipRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    membershipID: membershipID,
                    childID: currentChild.id,
                    actingMembership: currentMembership
                ))

            Task { @MainActor in
                do {
                    try await syncEngine.removeParticipant(membership: removedMembership)
                } catch {
                    AppLogger.shared.log(.error, category: "CloudKitShare", "removeParticipant failed for membership \(removedMembership.id): \(error)")
                }
                refresh(selecting: childSelectionStore.loadSelectedChildID())
            }
        }
    }

    public func leaveChildShare() {
        guard let currentChild, let currentMembership,
              currentMembership.role == .caregiver && currentMembership.status == .active else { return }
        let childID = currentChild.id
        let membership = currentMembership
        Task { @MainActor in
            do {
                // Push .removed membership to CloudKit before leaving so the owner's
                // device receives the status update and shows the caregiver in Past Access.
                let removedMembership = try membership.removed()
                try membershipRepository.saveMembership(removedMembership)
                _ = await syncEngine.refreshAfterLocalWrite()
                try await syncEngine.leaveShare(childID: childID)
                try childRepository.purgeChildData(id: childID)
                if childSelectionStore.loadSelectedChildID() == childID {
                    childSelectionStore.saveSelectedChildID(nil)
                }
                playHaptic(.actionSucceeded)
                resetNavigationStack()
            } catch {
                AppLogger.shared.log(.error, category: "CloudKitShare", "leaveChildShare failed for child \(childID): \(error)")
                setErrorMessage(resolveErrorMessage(for: error))
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
        perform(onSuccess: handleSuccessfulEventLog) {
            guard let currentChild, let currentMembership else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            _ = try LogBreastFeedUseCase(
                eventRepository: eventRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    childID: currentChild.id,
                    localUserID: localUser.id,
                    durationMinutes: durationMinutes,
                    endTime: endTime,
                    side: side,
                    leftDurationSeconds: leftDurationSeconds,
                    rightDurationSeconds: rightDurationSeconds,
                    membership: currentMembership
                ))
        }
    }

    @discardableResult
    public func logBottleFeed(
        amountMilliliters: Int,
        occurredAt: Date,
        milkType: MilkType?
    ) -> Bool {
        perform(onSuccess: handleSuccessfulEventLog) {
            guard let currentChild, let currentMembership else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            _ = try LogBottleFeedUseCase(
                eventRepository: eventRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    childID: currentChild.id,
                    localUserID: localUser.id,
                    amountMilliliters: amountMilliliters,
                    occurredAt: occurredAt,
                    milkType: milkType,
                    membership: currentMembership
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
        perform(onSuccess: handleSuccessfulEventLog) {
            guard let currentChild, let currentMembership else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            _ = try LogNappyUseCase(
                eventRepository: eventRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    childID: currentChild.id,
                    localUserID: localUser.id,
                    type: type,
                    occurredAt: occurredAt,
                    peeVolume: peeVolume,
                    pooVolume: pooVolume,
                    pooColor: pooColor,
                    membership: currentMembership
                ))
        }
    }

    @discardableResult
    public func startSleep(startedAt: Date) -> Bool {
        let succeeded = perform(onSuccess: handleSuccessfulEventLog) {
            guard let currentChild, let currentMembership else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            _ = try StartSleepUseCase(
                eventRepository: eventRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    childID: currentChild.id,
                    localUserID: localUser.id,
                    startedAt: startedAt,
                    membership: currentMembership
                ))
        }
        if succeeded {
            scheduleSleepDriftNotificationIfNeeded()
        }
        return succeeded
    }

    @discardableResult
    public func logSleep(startedAt: Date, endedAt: Date) -> Bool {
        perform(onSuccess: handleSuccessfulEventLog) {
            guard let currentChild, let currentMembership else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            _ = try LogSleepUseCase(
                eventRepository: eventRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    childID: currentChild.id,
                    localUserID: localUser.id,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    membership: currentMembership
                ))
        }
    }

    @discardableResult
    public func endSleep(
        id: UUID,
        startedAt: Date,
        endedAt: Date
    ) -> Bool {
        let succeeded = perform {
            guard let currentMembership else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            _ = try EndSleepUseCase(
                eventRepository: eventRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    eventID: id,
                    localUserID: localUser.id,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    membership: currentMembership
                ))
        }
        if succeeded {
            cancelSleepDriftNotification()
            scheduleInactivityDriftNotificationIfNeeded()
        }
        return succeeded
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
            guard let currentMembership else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            try UpdateBreastFeedUseCase(
                eventRepository: eventRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    eventID: id,
                    localUserID: localUser.id,
                    durationMinutes: durationMinutes,
                    endTime: endTime,
                    side: side,
                    leftDurationSeconds: leftDurationSeconds,
                    rightDurationSeconds: rightDurationSeconds,
                    membership: currentMembership
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
            guard let currentMembership else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            try UpdateBottleFeedUseCase(
                eventRepository: eventRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    eventID: id,
                    localUserID: localUser.id,
                    amountMilliliters: amountMilliliters,
                    occurredAt: occurredAt,
                    milkType: milkType,
                    membership: currentMembership
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
            guard let currentMembership else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            try UpdateNappyUseCase(
                eventRepository: eventRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    eventID: id,
                    localUserID: localUser.id,
                    type: type,
                    occurredAt: occurredAt,
                    peeVolume: peeVolume,
                    pooVolume: pooVolume,
                    pooColor: pooColor,
                    membership: currentMembership
                ))
        }
    }

    public func sleepStartSuggestions() -> [(label: String, date: Date)] {
        guard let currentChild else { return [] }
        let timeline = (try? eventRepository.loadTimeline(for: currentChild.id, includingDeleted: false)) ?? []

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
            guard let currentMembership else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            try UpdateSleepUseCase(
                eventRepository: eventRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    eventID: id,
                    localUserID: localUser.id,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    membership: currentMembership
                ))
        }
    }

    @discardableResult
    public func resumeSleep(id: UUID, startedAt: Date) -> Bool {
        let succeeded = perform {
            guard let currentMembership else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            _ = try ResumeSleepUseCase(
                eventRepository: eventRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    eventID: id,
                    localUserID: localUser.id,
                    startedAt: startedAt,
                    membership: currentMembership
                ))
        }
        if succeeded {
            cancelSleepDriftNotification()
            scheduleSleepDriftNotificationIfNeeded()
        }
        return succeeded
    }

    @discardableResult
    public func deleteEvent(id: UUID) -> Bool {
        perform {
            guard let currentMembership else { throw ChildProfileValidationError.insufficientPermissions }
            guard let localUser else { throw ChildProfileValidationError.insufficientPermissions }
            clearUndoDeleteState()
            if let event = try DeleteEventUseCase(
                eventRepository: eventRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(
                    eventID: id,
                    localUserID: localUser.id,
                    membership: currentMembership
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
            _ = try RestoreDeletedEventUseCase(
                eventRepository: eventRepository,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
                .execute(.init(event: pendingUndoDeletedEvent, restoredBy: localUser.id))
            clearUndoDeleteState()
        }
    }

    @discardableResult
    private func perform(
        failureHaptic: HapticEvent = .actionFailed,
        onSuccess: (() -> Void)? = nil,
        _ operation: () throws -> Void
    ) -> Bool {
        do {
            try operation()
            onSuccess?()
            refresh(selecting: childSelectionStore.loadSelectedChildID())
            Task { @MainActor in
                await runSyncRefresh { await self.syncEngine.refreshAfterLocalWrite() }
            }
            return true
        } catch {
            AppLogger.shared.log(.error, category: "AppModel", "perform failed: \(error)")
            setErrorMessage(resolveErrorMessage(for: error), haptic: failureHaptic)
            refresh(selecting: childSelectionStore.loadSelectedChildID())
            return false
        }
    }

    private func handleSuccessfulEventLog() {
        let shouldRequestReview = HandleLoggedEventForAppReviewUseCase(
            stateStore: appReviewPromptStateStore
        )
        .execute(.init(minimumLoggedEventsBeforePrompt: 5))

        if shouldRequestReview {
            appReviewRequester.requestReview()
        }

        scheduleInactivityDriftNotificationIfNeeded()
    }

    private func scheduleSleepDriftNotificationIfNeeded() {
        Task { @MainActor in
            await scheduleSleepDriftNotificationIfNeededAsync()
        }
    }

    private func scheduleSleepDriftNotificationIfNeededAsync() async {
        guard isReminderNotificationsEnabled else { return }
        guard let child = currentChild, let activeSleep else { return }
        let completedSleeps = events
            .compactMap { event -> SleepEvent? in
                guard case let .sleep(s) = event, s.endedAt != nil else { return nil }
                return s
            }
            .sorted { ($0.endedAt ?? $0.startedAt) > ($1.endedAt ?? $1.startedAt) }
        await ScheduleSleepDriftNotificationUseCase.execute(
            input: .init(
                childID: child.id,
                childName: child.name,
                activeSleepStartedAt: activeSleep.startedAt,
                completedSleepEvents: completedSleeps
            ),
            notificationManager: localNotificationManager
        )
    }

    private func scheduleInactivityDriftNotificationIfNeeded() {
        Task { @MainActor in
            await scheduleInactivityDriftNotificationIfNeededAsync()
        }
    }

    private func scheduleInactivityDriftNotificationIfNeededAsync() async {
        guard isReminderNotificationsEnabled else { return }
        guard let child = currentChild else { return }
        guard let lastEvent = events.max(by: { $0.metadata.occurredAt < $1.metadata.occurredAt }) else { return }
        await ScheduleInactivityDriftNotificationUseCase.execute(
            input: .init(
                childID: child.id,
                childName: child.name,
                lastEventOccurredAt: lastEvent.metadata.occurredAt,
                allEvents: events
            ),
            notificationManager: localNotificationManager
        )
    }

    private func cancelSleepDriftNotification() {
        Task { @MainActor in
            await cancelSleepDriftNotificationAsync()
        }
    }

    private func cancelSleepDriftNotificationAsync() async {
        guard let child = currentChild else { return }
        await localNotificationManager.cancelSleepDriftNotification(childID: child.id)
    }

    private func cancelInactivityDriftNotification() {
        Task { @MainActor in
            await cancelInactivityDriftNotificationAsync()
        }
    }

    private func cancelInactivityDriftNotificationAsync() async {
        guard let child = currentChild else { return }
        await localNotificationManager.cancelInactivityDriftNotification(childID: child.id)
    }

    private func cancelAllDriftNotifications() {
        cancelSleepDriftNotification()
        cancelInactivityDriftNotification()
    }

    private func cancelAllDriftNotificationsAsync() async {
        await cancelSleepDriftNotificationAsync()
        await cancelInactivityDriftNotificationAsync()
    }

    private func rescheduleAllDriftNotifications() {
        Task { @MainActor in
            await rescheduleAllDriftNotificationsAsync()
        }
    }

    private func rescheduleAllDriftNotificationsAsync() async {
        guard isReminderNotificationsEnabled else {
            await cancelAllDriftNotificationsAsync()
            return
        }
        if activeSleep != nil {
            await scheduleSleepDriftNotificationIfNeededAsync()
        }
        await scheduleInactivityDriftNotificationIfNeededAsync()
    }

    private func refresh(selecting selectedChildID: UUID?) {
        do {
            localUser = try userIdentityRepository.loadLocalUser()

            guard let localUser else {
                route = .identityOnboarding
                activeChildren = []
                archivedChildren = []
                clearProfileData()
                stopLiveActivity()
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
                clearProfileData()
                stopLiveActivity()
                return
            }

            let effectiveSelectedChildID = selectedChildID ?? childSelectionStore.loadSelectedChildID()
            let selectedSummary = activeChildren.first(where: { summary in
                summary.child.id == effectiveSelectedChildID
            })

            if activeChildren.count > 1 && selectedSummary == nil {
                route = .childPicker
                clearProfileData()
                stopLiveActivity()
                return
            }

            let currentSummary = selectedSummary ?? activeChildren[0]
            childSelectionStore.saveSelectedChildID(currentSummary.child.id)
            synchronizeTimelineSelection(for: currentSummary.child.id)

            let visibleEvents = try loadVisibleEvents(for: currentSummary.child.id)
            let builtTimelinePages = try loadTimelinePages(
                child: currentSummary.child,
                for: currentSummary.child.id,
                days: timelineVisibleDays(for: timelineSelectedDay)
            )
            let currentActiveSleep = try eventRepository.loadActiveSleepEvent(for: currentSummary.child.id)
            let childMemberships = try membershipRepository.loadMemberships(for: currentSummary.child.id)
            let userIDs = childMemberships.map(\.userID)
            let users = try userIdentityRepository.loadUsers(for: userIDs)

            guard let resolvedMembership = childMemberships.first(where: { m in
                m.userID == localUser.id && m.status == .active
            }) else {
                throw ChildProfileValidationError.invalidMembershipTransition(from: .removed, to: .active)
            }

            let status = CloudKitStatusViewState(summary: syncEngine.statusSummary)
            let pendingCounts = (try? syncEngine.loadPendingChangeCounts()) ?? [:]
            let builtPendingChanges: [PendingChangeSummaryItem] = [
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
            let builtPendingInvites = syncEngine.pendingInvites(for: currentSummary.child.id).map { invite in
                PendingShareInviteViewState(
                    id: invite.id,
                    displayName: invite.displayName,
                    statusLabel: invite.acceptanceStatus == .pending ? "Pending invitation" : "Invited"
                )
            }
            let stripDataset = buildTimelineStripDatasetUseCase.execute(
                events: visibleEvents,
                calendar: calendar
            )

            // Set flat observable properties — triggers ViewModel recomputation
            events = visibleEvents
            currentChild = currentSummary.child
            currentMembership = resolvedMembership
            activeSleep = currentActiveSleep
            timelinePages = builtTimelinePages
            timelineStripColumns = buildTimelineStripColumns(from: stripDataset)
            cloudKitStatus = status
            memberships = childMemberships
            membershipUsers = users
            pendingChanges = builtPendingChanges
            pendingShareInvites = builtPendingInvites

            route = .childProfile
            UpdateFeedLiveActivityUseCase.execute(
                events: visibleEvents,
                child: currentSummary.child,
                activeSleep: currentActiveSleep,
                isLiveActivityEnabled: isLiveActivityEnabled,
                liveActivityManager: liveActivityManager,
                snapshotCache: liveActivitySnapshotCache
            )
        } catch {
            AppLogger.shared.log(.error, category: "AppModel", "refresh failed: \(error)")
            setErrorMessage(resolveErrorMessage(for: error))
            // Only redirect to identity onboarding when there is genuinely no
            // local user. Data errors (e.g. owner membership not yet synced on a
            // shared child) must not wipe out the user's session.
            if localUser == nil {
                route = .identityOnboarding
                stopLiveActivity()
            }
        }
    }

    private func stopLiveActivity() {
        ResetFeedLiveActivityUseCase.execute(
            liveActivityManager: liveActivityManager,
            snapshotCache: liveActivitySnapshotCache
        )
    }

    private func clearProfileData() {
        events = []
        currentChild = nil
        currentMembership = nil
        activeSleep = nil
        timelinePages = []
        timelineStripColumns = []
        memberships = []
        membershipUsers = []
        pendingChanges = []
        pendingShareInvites = []
        timelineChildID = nil
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

    private func loadVisibleEvents(for childID: UUID) throws -> [BabyEvent] {
        try eventRepository.loadTimeline(for: childID, includingDeleted: false)
    }

    private func loadTimelinePages(
        child: Child,
        for childID: UUID,
        days: [Date]
    ) throws -> [TimelineDayGridPageState] {
        try days.map { day in
            let dayStart = calendar.startOfDay(for: day)
            let events = try eventRepository.loadEvents(
                for: childID,
                on: day,
                calendar: calendar,
                includingDeleted: false
            )
            let gridDataset = buildTimelineDayGridDatasetUseCase.execute(
                events: events,
                day: dayStart,
                calendar: calendar
            )
            let grid = buildTimelineDayGridViewState(
                from: gridDataset,
                events: events,
                child: child,
                day: dayStart
            )

            return TimelineDayGridPageState(
                date: dayStart,
                dayTitle: timelineDayTitle(for: dayStart),
                shortWeekdayTitle: dayStart.formatted(.dateTime.weekday(.abbreviated)),
                isToday: calendar.isDateInToday(dayStart),
                grid: grid,
                emptyStateTitle: "No events for this day",
                emptyStateMessage: "Try another day or use Quick Log to add the next event."
            )
        }
    }

    private func buildTimelineDayGridViewState(
        from dataset: TimelineDayGridDataset,
        events: [BabyEvent],
        child: Child,
        day: Date
    ) -> TimelineDayGridViewState? {
        let eventsByID = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })

        let columns = dataset.columns.map { column in
            TimelineDayGridColumnViewState(
                kind: column.kind,
                title: timelineColumnTitle(for: column.kind),
                items: column.placements.compactMap { placement in
                    let groupedEvents = placement.eventIDs.compactMap { eventsByID[$0] }
                    guard !groupedEvents.isEmpty else {
                        return nil
                    }

                    return makeTimelineDayGridItem(
                        placement: placement,
                        events: groupedEvents,
                        child: child,
                        day: day,
                        slotMinutes: dataset.slotMinutes
                    )
                }
            )
        }

        let hasItems = columns.contains { !$0.items.isEmpty }
        guard hasItems else {
            return nil
        }

        return TimelineDayGridViewState(
            slotMinutes: dataset.slotMinutes,
            columns: columns
        )
    }

    private func makeTimelineDayGridItem(
        placement: TimelineDayGridPlacement,
        events: [BabyEvent],
        child: Child,
        day: Date,
        slotMinutes: Int
    ) -> TimelineDayGridItemViewState {
        if let event = events.first, events.count == 1 {
            let actionPayload = eventActionPayload(for: event)
            let lines = timelineDayGridLines(
                for: event,
                preferredFeedVolumeUnit: child.preferredFeedVolumeUnit
            )
            return TimelineDayGridItemViewState(
                id: event.id.uuidString,
                columnKind: placement.columnKind,
                startSlotIndex: placement.startSlotIndex,
                endSlotIndex: placement.endSlotIndex,
                eventIDs: placement.eventIDs,
                count: 1,
                title: lines.title,
                detailText: lines.detailText,
                timeText: lines.timeText,
                actionPayloads: [actionPayload]
            )
        }

        let actionPayloads = events.map(eventActionPayload(for:))
        return TimelineDayGridItemViewState(
            id: placement.eventIDs.map(\.uuidString).joined(separator: "-"),
            columnKind: placement.columnKind,
            startSlotIndex: placement.startSlotIndex,
            endSlotIndex: placement.endSlotIndex,
            eventIDs: placement.eventIDs,
            count: events.count,
            title: "\(events.count) events",
            detailText: groupedTimelineDetailText(for: events),
            timeText: groupedTimelineTimeText(
                day: day,
                startSlotIndex: placement.startSlotIndex,
                endSlotIndex: placement.endSlotIndex,
                slotMinutes: slotMinutes
            ),
            actionPayloads: actionPayloads,
            groupedEntries: events.compactMap {
                EventCardViewState(
                    event: $0,
                    preferredFeedVolumeUnit: child.preferredFeedVolumeUnit,
                    timestampText: timelineTimeText(for: $0)
                )
            }
        )
    }

    private func groupedTimelineDetailText(for events: [BabyEvent]) -> String {
        let uniqueTitles = Array(Set(events.map(BabyEventPresentation.title(for:)))).sorted()
        if uniqueTitles.count > 1 {
            return uniqueTitles.prefix(2).joined(separator: ", ")
        }

        return "Multiple events"
    }

    private func groupedTimelineTimeText(
        day: Date,
        startSlotIndex: Int,
        endSlotIndex: Int,
        slotMinutes: Int
    ) -> String {
        let start = calendar.date(
            byAdding: .minute,
            value: startSlotIndex * slotMinutes,
            to: day
        ) ?? day
        let end = calendar.date(
            byAdding: .minute,
            value: endSlotIndex * slotMinutes,
            to: day
        ) ?? day
        return "\(shortTimeText(for: start))-\(shortTimeText(for: end))"
    }

    private func timelineColumnTitle(for kind: TimelineDayGridColumnKind) -> String {
        switch kind {
        case .sleep:
            return "Sleep"
        case .nappy:
            return "Nappy"
        case .bottleFeed:
            return "Bottle"
        case .breastFeed:
            return "Breast"
        }
    }

    private func timelineTimeText(for event: BabyEvent) -> String {
        switch event {
        case let .breastFeed(feed):
            return "\(shortTimeText(for: feed.startedAt))-\(shortTimeText(for: feed.endedAt))"
        case let .bottleFeed(feed):
            return shortTimeText(for: feed.metadata.occurredAt)
        case let .sleep(sleep):
            if let endedAt = sleep.endedAt {
                return "\(shortTimeText(for: sleep.startedAt))-\(shortTimeText(for: endedAt))"
            }
            return "Started \(shortTimeText(for: sleep.startedAt))"
        case let .nappy(nappy):
            return shortTimeText(for: nappy.metadata.occurredAt)
        }
    }

    private func timelineDayGridLines(
        for event: BabyEvent,
        preferredFeedVolumeUnit: FeedVolumeUnit
    ) -> (
        title: String,
        detailText: String,
        timeText: String
    ) {
        switch event {
        case let .sleep(sleep):
            return (
                title: sleepDurationText(for: sleep),
                detailText: shortTimeText(for: sleep.startedAt),
                timeText: sleep.endedAt.map(shortTimeText(for:)) ?? ""
            )
        case let .nappy(nappy):
            return (
                title: timelineNappyTypeText(for: nappy.type),
                detailText: "",
                timeText: ""
            )
        case let .bottleFeed(feed):
            return (
                title: FeedVolumePresentation.amountText(
                    for: feed.amountMilliliters,
                    unit: preferredFeedVolumeUnit
                ),
                detailText: "",
                timeText: ""
            )
        case let .breastFeed(feed):
            let durationMinutes = max(1, Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60))
            return (
                title: DurationText.short(minutes: durationMinutes, minuteStyle: .word),
                detailText: "",
                timeText: ""
            )
        }
    }

    private func sleepDurationText(for sleep: SleepEvent) -> String {
        let end = sleep.endedAt ?? .now
        let durationMinutes = max(1, Int(end.timeIntervalSince(sleep.startedAt) / 60))
        return DurationText.short(minutes: durationMinutes)
    }

    private func timelineNappyTypeText(for type: NappyType) -> String {
        switch type {
        case .dry:
            "Dry"
        case .wee:
            "Pee"
        case .poo:
            "Poo"
        case .mixed:
            "Mixed"
        }
    }

    private func eventActionPayload(for event: BabyEvent) -> EventActionPayload {
        switch event {
        case let .breastFeed(feed):
            let durationMinutes = max(1, Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60))
            return .editBreastFeed(
                durationMinutes: durationMinutes,
                endTime: feed.endedAt,
                side: feed.side,
                leftDurationSeconds: feed.leftDurationSeconds,
                rightDurationSeconds: feed.rightDurationSeconds
            )
        case let .bottleFeed(feed):
            return .editBottleFeed(
                amountMilliliters: feed.amountMilliliters,
                occurredAt: feed.metadata.occurredAt,
                milkType: feed.milkType
            )
        case let .sleep(sleep):
            if let endedAt = sleep.endedAt {
                return .editSleep(startedAt: sleep.startedAt, endedAt: endedAt)
            }
            return .endSleep(startedAt: sleep.startedAt)
        case let .nappy(nappy):
            return .editNappy(
                type: nappy.type,
                occurredAt: nappy.metadata.occurredAt,
                peeVolume: nappy.peeVolume,
                pooVolume: nappy.pooVolume,
                pooColor: nappy.pooColor
            )
        }
    }

    private func shortTimeText(for date: Date) -> String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }

    private func eventTitle(for event: BabyEvent) -> String {
        BabyEventPresentation.title(for: event)
    }

    /// Cancels all in-flight background timer tasks (undo delete, sync indicator, transient message).
    /// Call this in test teardown to prevent leaked tasks from blocking the main actor between tests.
    public func cancelPendingTasks() {
        undoDeleteTask?.cancel()
        undoDeleteTask = nil
        syncIndicatorDismissTask?.cancel()
        syncIndicatorDismissTask = nil
        transientMessageDismissTask?.cancel()
        transientMessageDismissTask = nil
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

    private func nextSelectedChildID(afterDeleting deletedChildID: UUID) throws -> UUID? {
        guard let localUser else {
            return nil
        }

        return try childRepository
            .loadActiveChildren(for: localUser.id)
            .first(where: { $0.id != deletedChildID })?
            .id
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

    private func buildTimelineStripColumns(
        from dataset: TimelineStripDataset
    ) -> [TimelineStripDayColumnViewState] {
        dataset.columns.map { column in
            TimelineStripDayColumnViewState(
                date: column.date,
                shortWeekdayTitle: column.date.formatted(.dateTime.weekday(.abbreviated)),
                dayNumberTitle: column.date.formatted(.dateTime.day()),
                isToday: calendar.isDateInToday(column.date),
                slots: column.slots.map(\.kind)
            )
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

    private func timelineVisibleDays(for selectedDay: Date) -> [Date] {
        let normalizedDay = normalizedTimelineDay(for: selectedDay)
        var mondayCalendar = calendar
        mondayCalendar.firstWeekday = 2

        let components = mondayCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: normalizedDay)
        guard let weekStart = mondayCalendar.date(from: components) else {
            return [normalizedDay]
        }

        return (0..<7).compactMap { offset in
            mondayCalendar.date(byAdding: .day, value: offset, to: weekStart).map(normalizedTimelineDay(for:))
        }
    }


    // MARK: - CSV Import

    public func parseCSVForImport(data: Data) {
        guard let currentChild else {
            setCSVImportError("No active child selected")
            return
        }

        let parseResult = HuckleberryCSVParser().parse(data: data)

        do {
            let taggedEvents = try CheckImportDuplicatesUseCase(eventRepository: eventRepository)
                .execute(.init(events: parseResult.events, childID: currentChild.id))
            csvImportState = .previewing(ImportPreviewState(parseResult: parseResult, taggedEvents: taggedEvents))
        } catch {
            // If duplicate check fails, treat everything as new
            let taggedEvents = parseResult.events.map { TaggedImportEvent(event: $0, duplicateStatus: .new) }
            csvImportState = .previewing(ImportPreviewState(parseResult: parseResult, taggedEvents: taggedEvents))
        }
    }

    public func reportImportFileError(_ message: String) {
        setCSVImportError(message)
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
        guard let currentChild, let currentMembership, let localUser else {
            setCSVImportError("No active child selected")
            return
        }

        let eventsToImport = previewState.selectedEvents
        guard !eventsToImport.isEmpty else {
            setCSVImportError("No events selected to import")
            return
        }

        let importTotal = eventsToImport.count
        csvImportState = .importing(.init(completed: 0, total: importTotal))

        Task { @MainActor in
            do {
                let saveResult = try await ImportEventsUseCase(
                    eventRepository: eventRepository,
                    hapticFeedbackProvider: hapticFeedbackProvider
                )
                    .execute(
                        .init(
                            events: eventsToImport,
                            childID: currentChild.id,
                            localUserID: localUser.id,
                            membership: currentMembership
                        ),
                        onProgress: { [weak self] completed, total in
                            self?.csvImportState = .importing(.init(completed: completed, total: total))
                        }
                    )
                // Combine parse-level skips with save-level skips in the final result
                let result = CSVImportResult(
                    importedCount: saveResult.importedCount,
                    skippedParseCount: previewState.parseResult.skippedCount,
                    skippedSaveCount: saveResult.skippedSaveCount,
                    skippedReasons: previewState.parseResult.skippedReasons + saveResult.skippedReasons
                )
                csvImportState = .complete(result)
                refresh(selecting: childSelectionStore.loadSelectedChildID())
                await runSyncRefresh { await self.syncEngine.refreshAfterLocalWrite() }
            } catch {
                setCSVImportError(resolveErrorMessage(for: error))
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
        guard let currentChild, let currentMembership else {
            setDataExportError("No active child selected")
            return
        }

        dataExportState = .exporting

        Task { @MainActor in
            do {
                let tempURL = try performExport(child: currentChild, membership: currentMembership)
                dataExportState = .ready(tempURL)
            } catch {
                setDataExportError(resolveErrorMessage(for: error))
            }
        }
    }

    public func dismissExport() {
        dataExportState = .idle
    }

    /// Executes the export and returns the temp-file URL. Used by ``ExportViewModel``.
    public func performExport(child: Child, membership: Membership) throws -> URL {
        let data = try ExportEventsUseCase(
            eventRepository: eventRepository,
            hapticFeedbackProvider: hapticFeedbackProvider
        )
        .execute(.init(child: child, membership: membership))

        let childName = child.name
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0 == "-" }
        let dateStamp = Date().formatted(.iso8601.year().month().day())
        let fileName = "Nest-\(childName)-\(dateStamp).json"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tempURL, options: .atomic)
        return tempURL
    }

    // MARK: - Import delegation (used by ImportViewModel)

    /// Tags import candidates as new or duplicate. Used by ``ImportViewModel``.
    public func checkImportDuplicates(events: [ImportableEvent], childID: UUID) throws -> [TaggedImportEvent] {
        try CheckImportDuplicatesUseCase(eventRepository: eventRepository)
            .execute(.init(events: events, childID: childID))
    }

    /// Executes an import batch and triggers a data refresh. Used by ``ImportViewModel``.
    public func performImport(
        events: [ImportableEvent],
        childID: UUID,
        localUserID: UUID,
        membership: Membership,
        onProgress: @escaping @MainActor (Int, Int) -> Void
    ) async throws -> CSVImportResult {
        let result = try await ImportEventsUseCase(
            eventRepository: eventRepository,
            hapticFeedbackProvider: hapticFeedbackProvider
        )
        .execute(
            .init(events: events, childID: childID, localUserID: localUserID, membership: membership),
            onProgress: onProgress
        )
        refresh(selecting: childSelectionStore.loadSelectedChildID())
        await runSyncRefresh { await self.syncEngine.refreshAfterLocalWrite() }
        return result
    }

    /// Creates a new child profile and imports all events from a full Nest backup file.
    /// Both the child and every event receive fresh UUIDs.
    /// Used by the Add Child screen for the "restore from backup" use case.
    public func performImportChildFromNest(
        data: Data,
        onProgress: @escaping @MainActor (Int, Int) -> Void
    ) async throws -> ImportChildWithEventsUseCase.Output {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(NestExportData.self, from: data)

        guard let localUser else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        let output = try await ImportChildWithEventsUseCase(
            childRepository: childRepository,
            membershipRepository: membershipRepository,
            childSelectionStore: childSelectionStore,
            eventRepository: eventRepository,
            hapticFeedbackProvider: hapticFeedbackProvider
        ).execute(
            .init(exportData: exportData, localUser: localUser),
            onProgress: onProgress
        )

        refresh(selecting: output.child.id)
        await runSyncRefresh { await self.syncEngine.refreshAfterLocalWrite() }
        return output
    }

    // MARK: - Nest Import

    public func parseNestFileForImport(data: Data) {
        guard let currentChild else {
            setNestImportError("No active child selected")
            return
        }

        let parseResult = NestJSONParser().parse(data: data)

        guard !parseResult.events.isEmpty || parseResult.skippedCount > 0 else {
            setNestImportError("The selected file contains no recognisable events")
            return
        }

        do {
            let taggedEvents = try CheckImportDuplicatesUseCase(eventRepository: eventRepository)
                .execute(.init(events: parseResult.events, childID: currentChild.id))
            nestImportState = .previewing(ImportPreviewState(parseResult: parseResult, taggedEvents: taggedEvents))
        } catch {
            let taggedEvents = parseResult.events.map { TaggedImportEvent(event: $0, duplicateStatus: .new) }
            nestImportState = .previewing(ImportPreviewState(parseResult: parseResult, taggedEvents: taggedEvents))
        }
    }

    public func reportNestImportFileError(_ message: String) {
        setNestImportError(message)
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
        guard let currentChild, let currentMembership, let localUser else {
            setNestImportError("No active child selected")
            return
        }

        let eventsToImport = previewState.selectedEvents
        guard !eventsToImport.isEmpty else {
            setNestImportError("No events selected to import")
            return
        }

        let nestImportTotal = eventsToImport.count
        nestImportState = .importing(.init(completed: 0, total: nestImportTotal))

        Task { @MainActor in
            do {
                let saveResult = try await ImportEventsUseCase(
                    eventRepository: eventRepository,
                    hapticFeedbackProvider: hapticFeedbackProvider
                )
                    .execute(
                        .init(
                            events: eventsToImport,
                            childID: currentChild.id,
                            localUserID: localUser.id,
                            membership: currentMembership
                        ),
                        onProgress: { [weak self] completed, total in
                            self?.nestImportState = .importing(.init(completed: completed, total: total))
                        }
                    )
                let result = CSVImportResult(
                    importedCount: saveResult.importedCount,
                    skippedParseCount: previewState.parseResult.skippedCount,
                    skippedSaveCount: saveResult.skippedSaveCount,
                    skippedReasons: previewState.parseResult.skippedReasons + saveResult.skippedReasons
                )
                nestImportState = .complete(result)
                refresh(selecting: childSelectionStore.loadSelectedChildID())
                await runSyncRefresh { await self.syncEngine.refreshAfterLocalWrite() }
            } catch {
                setNestImportError(resolveErrorMessage(for: error))
            }
        }
    }

    public func cancelNestImport() {
        nestImportState = .idle
    }

    public func dismissNestImportResult() {
        nestImportState = .idle
    }

    private func scheduleRemoteSyncNotificationIfNeeded() async {
        let changes = syncEngine.consumeRemoteCaregiverEventChanges()
        let input = BuildRemoteCaregiverNotificationUseCase.Input(changes: changes)
        guard let content = buildRemoteNotificationUseCase.execute(input) else {
            return
        }

        await localNotificationManager.scheduleRemoteSyncNotification(content)
    }

    private func runSyncRefresh(
        _ operation: @escaping @MainActor () async -> SyncStatusSummary
    ) async {
        setSyncIndicator(.syncing)
        let summary = await operation()
        refresh(selecting: childSelectionStore.loadSelectedChildID())
        updateSyncIndicator(using: summary)
    }

    private func updateSyncIndicator(using summary: SyncStatusSummary) {
        switch summary.state {
        case .upToDate:
            guard summary.lastSyncAt != nil else {
                setSyncIndicator(nil)
                return
            }

            setSyncIndicator(.synced)
            syncIndicatorDismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.2))
                guard !Task.isCancelled else { return }
                syncBannerState = nil
            }
        case .failed:
            let cloudKitStatus = CloudKitStatusViewState(summary: summary)
            guard !cloudKitStatus.isAccountUnavailable else {
                setSyncIndicator(nil)
                return
            }

            let message = cloudKitStatus.detailMessage ?? "Sync failed. Local changes are still saved."
            let state: SyncBannerState
            state = .lastSyncFailed(message)
            setSyncIndicator(state)
            playHaptic(.actionFailed)
            syncIndicatorDismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }
                syncBannerState = nil
            }
        default:
            setSyncIndicator(nil)
        }
    }

    private func setSyncIndicator(_ state: SyncBannerState?) {
        syncIndicatorDismissTask?.cancel()
        syncIndicatorDismissTask = nil
        syncBannerState = state
    }

    private func setErrorMessage(
        _ message: String,
        haptic: HapticEvent = .actionFailed
    ) {
        if CloudKitStatusViewState.isAccountUnavailableMessage(message) {
            errorMessage = nil
            return
        }

        errorMessage = message
        playHaptic(haptic)
    }

    private func setCSVImportError(_ message: String) {
        csvImportState = .error(message)
        playHaptic(.actionFailed)
    }

    private func setNestImportError(_ message: String) {
        nestImportState = .error(message)
        playHaptic(.actionFailed)
    }

    private func setDataExportError(_ message: String) {
        dataExportState = .error(message)
        playHaptic(.actionFailed)
    }

    private func showTransientMessage(_ message: String) {
        transientMessageDismissTask?.cancel()
        transientMessage = message
        transientMessageDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))

            guard !Task.isCancelled else {
                return
            }

            transientMessage = nil
        }
    }

    private func resetNavigationStack() {
        navigationResetToken &+= 1
    }

    private func playHaptic(_ event: HapticEvent) {
        hapticFeedbackProvider.play(event)
    }
}
