import BabyTrackerDomain
import BabyTrackerFeature
import BabyTrackerPersistence
import BabyTrackerSync
import Foundation
import Testing

@MainActor
struct AppModelTests {
    @Test
    func loadingWithoutLocalUserRoutesToIdentityOnboarding() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        harness.model.load(performLaunchSync: false)

        #expect(harness.model.route == .identityOnboarding)
        #expect(harness.model.localUser == nil)
    }

    @Test
    func creatingLocalUserRoutesToNoChildren() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        harness.model.load(performLaunchSync: false)
        harness.model.createLocalUser(displayName: "Alex Parent")

        #expect(harness.model.route == .noChildren)
        #expect(harness.model.localUser?.displayName == "Alex Parent")
    }

    @Test
    func dismissingReplayedOnboardingReturnsExistingUserToNoChildren() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        harness.model.createLocalUser(displayName: "Alex Parent")
        harness.model.showOnboarding()

        #expect(harness.model.route == .identityOnboarding)

        harness.model.dismissOnboarding()

        #expect(harness.model.route == .noChildren)
        #expect(harness.model.localUser?.displayName == "Alex Parent")
    }

    @Test
    func profileDerivesHomeRecentEventsInNewestFirstOrder() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let earlierFeed = try harness.saveBreastFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            start: Date(timeIntervalSince1970: 1_000),
            end: Date(timeIntervalSince1970: 1_600),
            side: .left
        )
        let laterFeed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 150,
            occurredAt: Date(timeIntervalSince1970: 2_000),
            milkType: .formula
        )

        harness.model.load(performLaunchSync: false)

        let child = try #require(harness.model.currentChild)
        let recentEvents = Array(BuildEventCardsUseCase.execute(events: harness.model.events, preferredFeedVolumeUnit: child.preferredFeedVolumeUnit).prefix(6))

        #expect(recentEvents.count == 2)
        #expect(recentEvents.map(\.id) == [laterFeed.id, earlierFeed.id])
        #expect(recentEvents.first?.detailText == "150 mL • Formula")
    }

    @Test
    func profileDerivesEventHistoryInNewestFirstOrder() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let earlierNappy = try harness.saveNappy(
            childID: seed.child.id,
            userID: seed.localUser.id,
            type: .wee,
            occurredAt: Date(timeIntervalSince1970: 1_500),
            peeVolume: .light,
            pooColor: nil
        )
        let laterNappy = try harness.saveNappy(
            childID: seed.child.id,
            userID: seed.localUser.id,
            type: .mixed,
            occurredAt: Date(timeIntervalSince1970: 2_500),
            pooVolume: .heavy,
            pooColor: .green
        )

        harness.model.load(performLaunchSync: false)

        let child = try #require(harness.model.currentChild)
        let eventCards = BuildEventCardsUseCase.execute(events: harness.model.events, preferredFeedVolumeUnit: child.preferredFeedVolumeUnit)

        #expect(eventCards.count == 2)
        #expect(eventCards.map(\.id) == [laterNappy.id, earlierNappy.id])
        #expect(eventCards.first?.detailText == "Mixed • Poo: Heavy • Green")
    }

    @Test
    func homeRecentEventsAreCappedAtSixItems() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()

        for index in 0..<8 {
            _ = try harness.saveBottleFeed(
                childID: seed.child.id,
                userID: seed.localUser.id,
                amountMilliliters: 100 + index,
                occurredAt: Date(timeIntervalSince1970: TimeInterval(1_000 + index)),
                milkType: nil
            )
        }

        harness.model.load(performLaunchSync: false)

        let child = try #require(harness.model.currentChild)
        let allEventCards = BuildEventCardsUseCase.execute(events: harness.model.events, preferredFeedVolumeUnit: child.preferredFeedVolumeUnit)
        #expect(Array(allEventCards.prefix(6)).count == 6)
        #expect(allEventCards.count == 8)
    }



    @Test
    func modelExposesActiveChildrenForProfileSelection() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let secondChild = try harness.saveOwnedChild(
            name: "Juniper",
            owner: seed.localUser
        )

        harness.model.load(performLaunchSync: false)

        #expect(harness.model.route == .childProfile)
        #expect(harness.model.activeChildren.map(\.child.id) == [seed.child.id, secondChild.id])
    }

    @Test
    func timelineDerivesMixedDayGridItemsForEachEventType() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)
        let breastStart = try #require(calendar.date(byAdding: .hour, value: 6, to: today))
        let breastEnd = try #require(calendar.date(byAdding: .minute, value: 20, to: breastStart))
        let sleepStart = try #require(calendar.date(byAdding: .hour, value: 9, to: today))
        let sleepEnd = try #require(calendar.date(byAdding: .hour, value: 11, to: today))
        let bottleTime = try #require(calendar.date(byAdding: .hour, value: 10, to: today))
        let nappyTime = try #require(calendar.date(byAdding: .hour, value: 12, to: today))

        let breastFeed = try harness.saveBreastFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            start: breastStart,
            end: breastEnd,
            side: .left
        )
        let sleep = try harness.saveSleep(
            childID: seed.child.id,
            userID: seed.localUser.id,
            startedAt: sleepStart,
            endedAt: sleepEnd
        )
        let bottleFeed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 150,
            occurredAt: bottleTime,
            milkType: .formula
        )
        let nappy = try harness.saveNappy(
            childID: seed.child.id,
            userID: seed.localUser.id,
            type: .mixed,
            occurredAt: nappyTime,
            pooVolume: .heavy,
            pooColor: .green
        )

        harness.model.load(performLaunchSync: false)

        let items = selectedTimelineItems(
            pages: harness.model.timelinePages,
            selectedDay: harness.model.timelineSelectedDay
        )
        let breastFeedItem = try #require(
            items.first(where: { $0.primaryEventID == breastFeed.id })
        )
        let sleepItem = try #require(
            items.first(where: { $0.primaryEventID == sleep.id })
        )
        let bottleFeedItem = try #require(
            items.first(where: { $0.primaryEventID == bottleFeed.id })
        )
        let nappyItem = try #require(
            items.first(where: { $0.primaryEventID == nappy.id })
        )
        let firstWeekday = Calendar.autoupdatingCurrent.component(
            .weekday,
            from: try #require(harness.model.timelinePages.first?.date)
        )

        #expect(items.count == 4)
        #expect(harness.model.timelinePages.count == 7)
        #expect(firstWeekday == 2)
        #expect(breastFeedItem.columnKind == .breastFeed)
        #expect(breastFeedItem.startSlotIndex == 24)
        #expect(breastFeedItem.endSlotIndex == 26)
        #expect(breastFeedItem.title == "20 min")
        #expect(sleepItem.columnKind == .sleep)
        #expect(sleepItem.startSlotIndex == 36)
        #expect(sleepItem.endSlotIndex == 44)
        #expect(sleepItem.title == "2h")
        #expect(sleepItem.detailText == "09:00")
        #expect(sleepItem.timeText == "11:00")
        #expect(bottleFeedItem.columnKind == .bottleFeed)
        #expect(bottleFeedItem.startSlotIndex == 40)
        #expect(bottleFeedItem.endSlotIndex == 41)
        #expect(bottleFeedItem.title == "150 mL")
        #expect(nappyItem.columnKind == .nappy)
        #expect(nappyItem.startSlotIndex == 48)
        #expect(nappyItem.endSlotIndex == 49)
        #expect(nappyItem.title == "Mixed")
        #expect(bottleFeedItem.primaryActionPayload == .editBottleFeed(
            amountMilliliters: 150,
            occurredAt: bottleTime,
            milkType: .formula
        ))
    }

    @Test
    func timelineShowsHourAwareBreastFeedTitles() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)
        let breastStart = try #require(calendar.date(byAdding: .hour, value: 6, to: today))
        let breastEnd = try #require(calendar.date(byAdding: .minute, value: 80, to: breastStart))

        let breastFeed = try harness.saveBreastFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            start: breastStart,
            end: breastEnd,
            side: .left
        )

        harness.model.load(performLaunchSync: false)

        let items = selectedTimelineItems(
            pages: harness.model.timelinePages,
            selectedDay: harness.model.timelineSelectedDay
        )
        let breastFeedItem = try #require(
            items.first(where: { $0.primaryEventID == breastFeed.id })
        )

        #expect(breastFeedItem.title == "1h 20m")
    }

    @Test
    func timelineNavigationMovesBetweenDaysAndDisablesForwardNavigationOnToday() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))
        let todayEventTime = try #require(calendar.date(byAdding: .hour, value: 8, to: today))
        let yesterdayEventTime = try #require(calendar.date(byAdding: .hour, value: 8, to: yesterday))

        let yesterdayEvent = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 120,
            occurredAt: yesterdayEventTime,
            milkType: nil
        )
        let todayEvent = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 150,
            occurredAt: todayEventTime,
            milkType: .formula
        )

        harness.model.load(performLaunchSync: false)

        #expect(selectedTimelineItems(pages: harness.model.timelinePages, selectedDay: harness.model.timelineSelectedDay).compactMap(\.primaryEventID) == [todayEvent.id])
        #expect(Calendar.autoupdatingCurrent.isDateInToday(harness.model.timelineSelectedDay))
        #expect(harness.model.timelinePages.count == 7)

        harness.model.showPreviousTimelineDay()

        #expect(selectedTimelineItems(pages: harness.model.timelinePages, selectedDay: harness.model.timelineSelectedDay).compactMap(\.primaryEventID) == [yesterdayEvent.id])
        #expect(!Calendar.autoupdatingCurrent.isDateInToday(harness.model.timelineSelectedDay))

        harness.model.showNextTimelineDay()

        #expect(selectedTimelineItems(pages: harness.model.timelinePages, selectedDay: harness.model.timelineSelectedDay).compactMap(\.primaryEventID) == [todayEvent.id])
    }

    @Test
    func activeSleepAppearsOnTimelineDayGridWithEndAction() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)
        // Use 1 AM so the sleep always started before .now regardless of when
        // CI runs, avoiding a flaky failure when the test runs before 7 AM.
        let start = try #require(calendar.date(byAdding: .hour, value: 1, to: today))

        let activeSleep = try harness.saveSleep(
            childID: seed.child.id,
            userID: seed.localUser.id,
            startedAt: start,
            endedAt: nil
        )

        harness.model.load(performLaunchSync: false)

        let item = try #require(
            selectedTimelineItems(
                pages: harness.model.timelinePages,
                selectedDay: harness.model.timelineSelectedDay
            ).first(where: { $0.primaryEventID == activeSleep.id })
        )

        #expect(item.startSlotIndex == 4)
        #expect(item.endSlotIndex > item.startSlotIndex)
        #expect(item.primaryActionPayload == .endSleep(startedAt: start))
    }

    @Test
    func selectingDifferentChildResetsTimelineDayToToday() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let secondChild = try harness.saveOwnedChild(
            name: "Juniper",
            owner: seed.localUser
        )

        harness.model.load(performLaunchSync: false)
        harness.model.showPreviousTimelineDay()
        harness.model.selectChild(id: secondChild.id)

        #expect(Calendar.autoupdatingCurrent.isDateInToday(harness.model.timelineSelectedDay))
    }

    @Test
    func selectingDifferentChildResetsNavigationAndShowsProfileFeedback() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let secondChild = try harness.saveOwnedChild(
            name: "Juniper",
            owner: seed.localUser
        )

        harness.model.load(performLaunchSync: false)
        harness.model.selectedWorkspaceTab = .timeline
        let previousResetToken = harness.model.navigationResetToken

        harness.model.selectChild(id: secondChild.id)

        #expect(harness.model.currentChild?.id == secondChild.id)
        #expect(harness.model.selectedWorkspaceTab == .profile)
        #expect(harness.model.transientMessage == "Child changed.")
        #expect(harness.model.navigationResetToken == previousResetToken + 1)
    }

    @Test
    func reselectingCurrentChildDoesNotResetNavigationOrShowSwitchMessage() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()

        harness.model.load(performLaunchSync: false)
        harness.model.selectedWorkspaceTab = .summary
        let previousResetToken = harness.model.navigationResetToken

        harness.model.selectChild(id: seed.child.id)

        #expect(harness.model.selectedWorkspaceTab == .summary)
        #expect(harness.model.transientMessage == nil)
        #expect(harness.model.navigationResetToken == previousResetToken)
    }

    @Test
    func timelineShowsSyncMessageWhenSyncStatusIsNotUpToDate() async throws {
        let syncEngine = TestSyncEngine()
        syncEngine.refreshForegroundSummary = SyncStatusSummary(
            state: .failed,
            pendingRecordCount: 0,
            lastSyncAt: nil,
            lastErrorDescription: "Sync unavailable. Sign in to iCloud."
        )
        let harness = try Harness(syncEngine: syncEngine)
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()

        harness.model.load(performLaunchSync: false)
        _ = await harness.syncEngine.refreshForeground()
        harness.model.load(performLaunchSync: false)

        #expect(harness.model.cloudKitStatus.state == .failed)
        #expect(harness.model.cloudKitStatus.isAccountUnavailable)
        let timelineVM = TimelineViewModel(appModel: harness.model)
        #expect(timelineVM.syncMessage == nil)
    }

    @Test
    func syncIndicatorSuppressesUnavailableStateAfterFailedRefresh() async throws {
        let syncEngine = TestSyncEngine()
        syncEngine.refreshForegroundSummary = SyncStatusSummary(
            state: .failed,
            pendingRecordCount: 0,
            lastSyncAt: nil,
            lastErrorDescription: "Sync unavailable. Sign in to iCloud."
        )
        let harness = try Harness(syncEngine: syncEngine)
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()
        harness.model.load(performLaunchSync: false)

        await harness.model.refreshSyncStatus()

        #expect(harness.model.syncBannerState == nil)
    }

    @Test
    func successfulSyncRefreshShowsSyncedIndicator() async throws {
        let syncEngine = TestSyncEngine()
        syncEngine.refreshForegroundSummary = SyncStatusSummary(
            state: .upToDate,
            pendingRecordCount: 0,
            lastSyncAt: Date(timeIntervalSince1970: 2_000),
            lastErrorDescription: nil
        )
        let harness = try Harness(syncEngine: syncEngine)
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()
        harness.model.load(performLaunchSync: false)

        await harness.model.refreshSyncStatus()

        #expect(harness.model.syncBannerState == .synced)
    }

    @Test
    func homeSyncStatusUsesSharedCloudKitStatusSummary() throws {
        let syncEngine = TestSyncEngine()
        syncEngine.statusSummary = SyncStatusSummary(
            state: .pendingSync,
            pendingRecordCount: 2,
            lastSyncAt: nil,
            lastErrorDescription: nil
        )
        let harness = try Harness(syncEngine: syncEngine)
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()
        harness.model.load(performLaunchSync: false)

        #expect(harness.model.cloudKitStatus.statusTitle == "Waiting to sync")
        #expect(harness.model.cloudKitStatus.pendingChangesTitle == "2 changes")
    }

    @Test
    func failedSyncRefreshShowsFailureIndicatorForRecoverableErrors() async throws {
        let syncEngine = TestSyncEngine()
        syncEngine.refreshForegroundSummary = SyncStatusSummary(
            state: .failed,
            pendingRecordCount: 0,
            lastSyncAt: nil,
            lastErrorDescription: "Network connection was lost."
        )
        let harness = try Harness(syncEngine: syncEngine)
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()
        harness.model.load(performLaunchSync: false)

        await harness.model.refreshSyncStatus()

        #expect(harness.model.syncBannerState == .lastSyncFailed("Network connection was lost."))
    }

    @Test
    func timelineWeekUsesEventPrecedenceAndShowsAtLeastSevenColumns() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)
        let slotStart = try #require(calendar.date(byAdding: .hour, value: 10, to: today))
        let slotEnd = try #require(calendar.date(byAdding: .minute, value: 45, to: slotStart))

        _ = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 120,
            occurredAt: slotStart,
            milkType: nil
        )
        _ = try harness.saveNappy(
            childID: seed.child.id,
            userID: seed.localUser.id,
            type: .wee,
            occurredAt: slotStart,
            pooColor: nil
        )
        _ = try harness.saveSleep(
            childID: seed.child.id,
            userID: seed.localUser.id,
            startedAt: slotStart,
            endedAt: slotEnd
        )

        harness.model.load(performLaunchSync: false)
        harness.model.toggleTimelineDisplayMode()

        let todayColumn = try #require(harness.model.timelineStripColumns.last(where: { $0.isToday }))
        let tenAMSlot = (10 * 60) / BuildTimelineStripDatasetUseCase.defaultSlotMinutes

        #expect(harness.model.timelineDisplayMode == .week)
        #expect(harness.model.timelineStripColumns.count >= 7)
        #expect(
            todayColumn.slots.count ==
                (24 * 60) / BuildTimelineStripDatasetUseCase.defaultSlotMinutes
        )
        #expect(todayColumn.slots[tenAMSlot] == .sleep)
    }

    @Test
    func mixedTimelineDerivesHomeStatusAndLatestFeedForLiveActivity() throws {
        let liveActivityManager = LiveActivityManagerSpy()
        let harness = try Harness(liveActivityManager: liveActivityManager)
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let feed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 120,
            occurredAt: Date(timeIntervalSince1970: 1_000),
            milkType: .formula
        )
        let sleep = try harness.saveSleep(
            childID: seed.child.id,
            userID: seed.localUser.id,
            startedAt: Date(timeIntervalSince1970: 1_800),
            endedAt: Date(timeIntervalSince1970: 3_000)
        )

        harness.model.load(performLaunchSync: false)

        let child = try #require(harness.model.currentChild)
        #expect(harness.model.activeSleep == nil)
        let currentStatus = BuildCurrentStatusViewStateUseCase.execute(events: harness.model.events, child: child)
        #expect(currentStatus.timeSinceLastFeedAt == feed.metadata.occurredAt)
        #expect(currentStatus.timeSinceLastNappyAt == nil)
        let recentEvents = Array(BuildEventCardsUseCase.execute(events: harness.model.events, preferredFeedVolumeUnit: child.preferredFeedVolumeUnit).prefix(6))
        #expect(recentEvents.map(\.id) == [sleep.id, feed.id])
        #expect(
            liveActivityManager.latestSnapshot == FeedLiveActivitySnapshot(
                childID: seed.child.id,
                childName: seed.child.name,
                lastFeedKind: .bottleFeed,
                lastFeedAt: feed.metadata.occurredAt,
                lastSleepAt: sleep.endedAt,
                activeSleepStartedAt: nil,
                lastNappyAt: nil
            )
        )
    }

    @Test
    func homeStatusUsesLatestFeedAndNappyAndCountsTodayFeeds() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let calendar = Calendar.autoupdatingCurrent
        let startOfToday = calendar.startOfDay(for: .now)
        let firstFeed = try #require(calendar.date(byAdding: .hour, value: 8, to: startOfToday))
        let secondFeed = try #require(calendar.date(byAdding: .hour, value: 12, to: startOfToday))
        let nappyTime = try #require(calendar.date(byAdding: .hour, value: 13, to: startOfToday))

        _ = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 90,
            occurredAt: firstFeed,
            milkType: nil
        )
        let latestFeed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 120,
            occurredAt: secondFeed,
            milkType: nil
        )
        let latestNappy = try harness.saveNappy(
            childID: seed.child.id,
            userID: seed.localUser.id,
            type: .wee,
            occurredAt: nappyTime,
            peeVolume: .medium,
            pooColor: nil
        )

        harness.model.load(performLaunchSync: false)

        let child = try #require(harness.model.currentChild)
        let currentStatus = BuildCurrentStatusViewStateUseCase.execute(events: harness.model.events, child: child)
        #expect(currentStatus.timeSinceLastFeedAt == latestFeed.metadata.occurredAt)
        #expect(currentStatus.feedsTodayCount == 2)
        #expect(currentStatus.timeSinceLastNappyAt == latestNappy.metadata.occurredAt)
    }

    @Test
    func activeCaregiverCanEditAndDeleteFeedEvents() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedActiveCaregiverProfile()
        let feed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.owner.id,
            amountMilliliters: 120,
            occurredAt: Date(timeIntervalSince1970: 3_000),
            milkType: nil
        )

        harness.model.load(performLaunchSync: false)

        let membership = try #require(harness.model.currentMembership)
        #expect(ChildAccessPolicy.canPerform(.editEvent, membership: membership))

        #expect(
            harness.model.updateBottleFeed(
                id: feed.id,
                amountMilliliters: 180,
                occurredAt: Date(timeIntervalSince1970: 3_600),
                milkType: .formula
            )
        )

        let updatedEvent = try #require(try harness.eventRepository.loadEvent(id: feed.id))
        switch updatedEvent {
        case let .bottleFeed(event):
            #expect(event.amountMilliliters == 180)
            #expect(event.milkType == .formula)
        default:
            Issue.record("Expected an updated bottle feed")
        }

        #expect(harness.model.deleteEvent(id: feed.id))

        let visibleTimeline = try harness.eventRepository.loadTimeline(
            for: seed.child.id,
            includingDeleted: false
        )
        #expect(visibleTimeline.isEmpty)
        #expect(harness.model.undoDeleteMessage == "Bottle Feed deleted")
    }

    @Test
    func activeCaregiverCanLogEditDeleteAndUndoNappyEvents() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedActiveCaregiverProfile()

        harness.model.load(performLaunchSync: false)

        let membership = try #require(harness.model.currentMembership)
        #expect(ChildAccessPolicy.canPerform(.logEvent, membership: membership))
        #expect(ChildAccessPolicy.canPerform(.editEvent, membership: membership))

        #expect(
            harness.model.logNappy(
                type: .poo,
                occurredAt: Date(timeIntervalSince1970: 6_000),
                pooVolume: .medium,
                pooColor: .brown
            )
        )

        let loggedNappy = try #require(
            try harness.eventRepository.loadTimeline(
                for: seed.child.id,
                includingDeleted: false
            ).compactMap { event -> NappyEvent? in
                guard case let .nappy(nappy) = event else {
                    return nil
                }

                return nappy
            }.first
        )

        #expect(
            harness.model.updateNappy(
                id: loggedNappy.id,
                type: .mixed,
                occurredAt: Date(timeIntervalSince1970: 6_600),
                pooVolume: .heavy,
                pooColor: .green
            )
        )

        let updatedEvent = try #require(try harness.eventRepository.loadEvent(id: loggedNappy.id))
        switch updatedEvent {
        case let .nappy(event):
            #expect(event.type == .mixed)
            #expect(event.pooVolume == .heavy)
            #expect(event.pooColor == .green)
        default:
            Issue.record("Expected an updated nappy event")
        }

        #expect(harness.model.deleteEvent(id: loggedNappy.id))
        #expect(harness.model.undoDeleteMessage == "Nappy deleted")

        harness.model.undoLastDeletedEvent()

        let visibleTimeline = try harness.eventRepository.loadTimeline(
            for: seed.child.id,
            includingDeleted: false
        )
        #expect(visibleTimeline.count == 1)
        #expect(visibleTimeline.first?.id == loggedNappy.id)
    }

    @Test
    func startSleepCreatesRecoverableActiveSessionAndEndSleepCompletesIt() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let sleepStart = Date(timeIntervalSince1970: 8_000)
        let sleepEnd = sleepStart.addingTimeInterval(3_600)

        harness.model.load(performLaunchSync: false)

        #expect(harness.model.startSleep(startedAt: sleepStart))

        let activeSleepState = try #require(harness.model.activeSleep.map(ActiveSleepSessionViewState.init))
        let child = try #require(harness.model.currentChild)
        let currentSleep = CurrentSleepCardViewState(sleepEventID: activeSleepState.id, startedAt: activeSleepState.startedAt)

        #expect(activeSleepState.startedAt == sleepStart)
        #expect(currentSleep.startedAt == sleepStart)
        #expect(currentSleep.sleepEventID == activeSleepState.id)
        let recentEvents1 = Array(BuildEventCardsUseCase.execute(events: harness.model.events, preferredFeedVolumeUnit: child.preferredFeedVolumeUnit).prefix(6))
        #expect(recentEvents1.map(\.id) == [activeSleepState.id])

        harness.model.load(performLaunchSync: false)

        let recoveredSleep = try #require(harness.model.activeSleep.map(ActiveSleepSessionViewState.init))
        #expect(recoveredSleep.id == activeSleepState.id)

        #expect(
            harness.model.endSleep(
                id: recoveredSleep.id,
                startedAt: recoveredSleep.startedAt,
                endedAt: sleepEnd
            )
        )

        let loadedEvent = try #require(try harness.eventRepository.loadEvent(id: recoveredSleep.id))
        switch loadedEvent {
        case let .sleep(event):
            #expect(event.id == recoveredSleep.id)
            #expect(event.startedAt == sleepStart)
            #expect(event.endedAt == sleepEnd)
            #expect(event.metadata.occurredAt == sleepEnd)
        default:
            Issue.record("Expected a completed sleep event")
        }

        #expect(harness.model.activeSleep == nil)
        let recentEvents2 = Array(BuildEventCardsUseCase.execute(events: harness.model.events, preferredFeedVolumeUnit: child.preferredFeedVolumeUnit).prefix(6))
        #expect(recentEvents2.map(\.id) == [recoveredSleep.id])

        let visibleTimeline = try harness.eventRepository.loadTimeline(
            for: seed.child.id,
            includingDeleted: false
        )
        #expect(visibleTimeline.count == 1)
    }

    @Test
    func startSleepFailsWhenAnotherActiveSleepExists() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()
        let initialStart = Date(timeIntervalSince1970: 8_500)

        harness.model.load(performLaunchSync: false)

        #expect(harness.model.startSleep(startedAt: initialStart))
        #expect(harness.model.startSleep(startedAt: initialStart.addingTimeInterval(600)) == false)
        #expect(harness.model.errorMessage == BabyEventError.activeSleepAlreadyInProgress.errorDescription)
    }

    @Test
    func logPastSleepSucceedsWhileAnotherSleepIsActive() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()
        let activeStart = Date(timeIntervalSince1970: 10_000)
        let pastStart = Date(timeIntervalSince1970: 5_000)
        let pastEnd = Date(timeIntervalSince1970: 7_000)

        harness.model.load(performLaunchSync: false)

        #expect(harness.model.startSleep(startedAt: activeStart))
        #expect(harness.model.activeSleep != nil)

        #expect(harness.model.logSleep(startedAt: pastStart, endedAt: pastEnd))

        #expect(harness.model.activeSleep != nil, "Active sleep should still be running")

        let events = try harness.eventRepository.loadTimeline(
            for: harness.model.currentChild!.id,
            includingDeleted: false
        )
        let sleepEvents = events.compactMap { event -> SleepEvent? in
            if case let .sleep(s) = event { return s }
            return nil
        }
        #expect(sleepEvents.count == 2)
        let loggedPast = try #require(sleepEvents.first(where: { $0.endedAt != nil }))
        #expect(loggedPast.startedAt == pastStart)
        #expect(loggedPast.endedAt == pastEnd)
    }

    @Test
    func resumeSleepClearsEndedAtAndMakesSleepActive() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let sleep = try harness.saveSleep(
            childID: seed.child.id,
            userID: seed.localUser.id,
            startedAt: Date(timeIntervalSince1970: 9_000),
            endedAt: Date(timeIntervalSince1970: 9_900)
        )

        harness.model.load(performLaunchSync: false)

        #expect(harness.model.resumeSleep(id: sleep.id, startedAt: sleep.startedAt))

        let resumedEvent = try #require(try harness.eventRepository.loadEvent(id: sleep.id))
        switch resumedEvent {
        case let .sleep(event):
            #expect(event.id == sleep.id)
            #expect(event.startedAt == sleep.startedAt)
            #expect(event.endedAt == nil)
            #expect(event.metadata.occurredAt == sleep.startedAt)
        default:
            Issue.record("Expected a resumed sleep event")
        }

        #expect(harness.model.activeSleep?.id == sleep.id)
    }

    @Test
    func resumeSleepFailsWhenSleepIsAlreadyActive() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let activeSleep = try harness.saveSleep(
            childID: seed.child.id,
            userID: seed.localUser.id,
            startedAt: Date(timeIntervalSince1970: 10_000),
            endedAt: nil
        )

        harness.model.load(performLaunchSync: false)

        #expect(harness.model.resumeSleep(id: activeSleep.id, startedAt: activeSleep.startedAt) == false)
        #expect(harness.model.errorMessage == BabyEventError.sleepAlreadyActive.errorDescription)
    }

    @Test
    func resumeSleepFailsForNonExistentEvent() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()

        harness.model.load(performLaunchSync: false)

        let missingID = UUID()
        #expect(harness.model.resumeSleep(id: missingID, startedAt: Date()) == false)
        #expect(harness.model.errorMessage == BabyEventError.noActiveSleepInProgress.errorDescription)
    }

    @Test
    func completedSleepCanBeEditedDeletedAndUndone() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let sleep = try harness.saveSleep(
            childID: seed.child.id,
            userID: seed.localUser.id,
            startedAt: Date(timeIntervalSince1970: 9_000),
            endedAt: Date(timeIntervalSince1970: 9_900)
        )

        harness.model.load(performLaunchSync: false)

        #expect(
            harness.model.updateSleep(
                id: sleep.id,
                startedAt: Date(timeIntervalSince1970: 9_300),
                endedAt: Date(timeIntervalSince1970: 10_200)
            )
        )

        let updatedEvent = try #require(try harness.eventRepository.loadEvent(id: sleep.id))
        switch updatedEvent {
        case let .sleep(event):
            #expect(event.startedAt == Date(timeIntervalSince1970: 9_300))
            #expect(event.endedAt == Date(timeIntervalSince1970: 10_200))
            #expect(event.metadata.occurredAt == Date(timeIntervalSince1970: 10_200))
        default:
            Issue.record("Expected an updated sleep event")
        }

        #expect(harness.model.deleteEvent(id: sleep.id))
        #expect(harness.model.undoDeleteMessage == "Sleep deleted")

        let deletedTimeline = try harness.eventRepository.loadTimeline(
            for: seed.child.id,
            includingDeleted: false
        )
        #expect(deletedTimeline.isEmpty)

        harness.model.undoLastDeletedEvent()

        let visibleTimeline = try harness.eventRepository.loadTimeline(
            for: seed.child.id,
            includingDeleted: false
        )
        #expect(visibleTimeline.count == 1)
        #expect(visibleTimeline.first?.id == sleep.id)
    }

    @Test
    func sleepMutationsKeepFeedFieldsStableAndUpdateSleepFields() throws {
        let liveActivityManager = LiveActivityManagerSpy()
        let harness = try Harness(liveActivityManager: liveActivityManager)
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let feed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 120,
            occurredAt: Date(timeIntervalSince1970: 11_000),
            milkType: .formula
        )

        harness.model.load(performLaunchSync: false)

        let originalSnapshot = try #require(liveActivityManager.latestSnapshot)
        #expect(originalSnapshot.lastFeedAt == feed.metadata.occurredAt)

        #expect(
            harness.model.startSleep(startedAt: Date(timeIntervalSince1970: 11_500))
        )
        #expect(liveActivityManager.latestSnapshot?.childID == originalSnapshot.childID)
        #expect(liveActivityManager.latestSnapshot?.lastFeedKind == originalSnapshot.lastFeedKind)
        #expect(liveActivityManager.latestSnapshot?.lastFeedAt == originalSnapshot.lastFeedAt)
        #expect(liveActivityManager.latestSnapshot?.activeSleepStartedAt == Date(timeIntervalSince1970: 11_500))
        #expect(liveActivityManager.latestSnapshot?.lastSleepAt == Date(timeIntervalSince1970: 11_500))

        let activeSleep = try #require(harness.model.activeSleep.map(ActiveSleepSessionViewState.init))

        #expect(
            harness.model.endSleep(
                id: activeSleep.id,
                startedAt: activeSleep.startedAt,
                endedAt: Date(timeIntervalSince1970: 12_100)
            )
        )
        #expect(liveActivityManager.latestSnapshot?.lastFeedAt == originalSnapshot.lastFeedAt)
        #expect(liveActivityManager.latestSnapshot?.activeSleepStartedAt == nil)
        #expect(liveActivityManager.latestSnapshot?.lastSleepAt == Date(timeIntervalSince1970: 12_100))

        #expect(
            harness.model.updateSleep(
                id: activeSleep.id,
                startedAt: Date(timeIntervalSince1970: 11_600),
                endedAt: Date(timeIntervalSince1970: 12_300)
            )
        )
        #expect(liveActivityManager.latestSnapshot?.lastFeedAt == originalSnapshot.lastFeedAt)
        #expect(liveActivityManager.latestSnapshot?.activeSleepStartedAt == nil)
        #expect(liveActivityManager.latestSnapshot?.lastSleepAt == Date(timeIntervalSince1970: 12_300))

        #expect(harness.model.deleteEvent(id: activeSleep.id))
        #expect(liveActivityManager.latestSnapshot?.lastFeedAt == originalSnapshot.lastFeedAt)
        #expect(liveActivityManager.latestSnapshot?.activeSleepStartedAt == nil)
        #expect(liveActivityManager.latestSnapshot?.lastSleepAt == nil)
    }

    @Test
    func undoRestoresDeletedFeedAndClearsBannerState() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let feed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 120,
            occurredAt: Date(timeIntervalSince1970: 4_000),
            milkType: nil
        )

        harness.model.load(performLaunchSync: false)

        #expect(harness.model.deleteEvent(id: feed.id))
        harness.model.undoLastDeletedEvent()

        let visibleTimeline = try harness.eventRepository.loadTimeline(
            for: seed.child.id,
            includingDeleted: false
        )
        #expect(visibleTimeline.count == 1)
        #expect(visibleTimeline.first?.id == feed.id)
        #expect(harness.model.undoDeleteMessage == nil)
    }

    @Test
    func secondDeleteReplacesFirstUndoTarget() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let firstFeed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 120,
            occurredAt: Date(timeIntervalSince1970: 5_000),
            milkType: nil
        )
        let secondFeed = try harness.saveBreastFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            start: Date(timeIntervalSince1970: 5_400),
            end: Date(timeIntervalSince1970: 5_700),
            side: .right
        )

        harness.model.load(performLaunchSync: false)

        #expect(harness.model.deleteEvent(id: firstFeed.id))
        #expect(harness.model.deleteEvent(id: secondFeed.id))

        harness.model.undoLastDeletedEvent()

        let visibleTimeline = try harness.eventRepository.loadTimeline(
            for: seed.child.id,
            includingDeleted: false
        )
        #expect(visibleTimeline.count == 1)
        #expect(visibleTimeline.first?.id == secondFeed.id)
        #expect(!visibleTimeline.contains(where: { $0.id == firstFeed.id }))
    }

    @Test
    func liveActivityManagerReceivesCreateUpdateDeleteAndUndoSnapshots() throws {
        let liveActivityManager = LiveActivityManagerSpy()
        let harness = try Harness(liveActivityManager: liveActivityManager)
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()

        harness.model.load(performLaunchSync: false)
        #expect(liveActivityManager.latestSnapshot == nil)

        #expect(
            harness.model.logBottleFeed(
                amountMilliliters: 120,
                occurredAt: Date(timeIntervalSince1970: 4_000),
                milkType: nil
            )
        )

        let loggedFeed = try #require(
            try harness.eventRepository.loadTimeline(
                for: seed.child.id,
                includingDeleted: false
            ).compactMap { event -> BottleFeedEvent? in
                guard case let .bottleFeed(feed) = event else {
                    return nil
                }

                return feed
            }.first
        )

        #expect(liveActivityManager.latestSnapshot?.lastFeedAt == loggedFeed.metadata.occurredAt)

        #expect(
            harness.model.updateBottleFeed(
                id: loggedFeed.id,
                amountMilliliters: 150,
                occurredAt: Date(timeIntervalSince1970: 4_600),
                milkType: .formula
            )
        )
        #expect(liveActivityManager.latestSnapshot?.lastFeedAt == Date(timeIntervalSince1970: 4_600))

        #expect(harness.model.deleteEvent(id: loggedFeed.id))
        #expect(liveActivityManager.latestSnapshot == nil)

        harness.model.undoLastDeletedEvent()
        #expect(liveActivityManager.latestSnapshot?.childID == seed.child.id)
        #expect(liveActivityManager.latestSnapshot?.lastFeedAt == Date(timeIntervalSince1970: 4_600))
    }

    @Test
    func loggingBottleFeedPlaysSuccessHaptic() throws {
        let hapticFeedbackProvider = HapticFeedbackProviderSpy()
        let harness = try Harness(hapticFeedbackProvider: hapticFeedbackProvider)
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()

        harness.model.load(performLaunchSync: false)

        #expect(
            harness.model.logBottleFeed(
                amountMilliliters: 120,
                occurredAt: Date(timeIntervalSince1970: 4_000),
                milkType: .formula
            )
        )

        #expect(hapticFeedbackProvider.events == [.actionSucceeded])
    }

    @Test
    func failedSleepStartPlaysErrorHaptic() throws {
        let hapticFeedbackProvider = HapticFeedbackProviderSpy()
        let harness = try Harness(hapticFeedbackProvider: hapticFeedbackProvider)
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()
        let initialStart = Date(timeIntervalSince1970: 8_500)

        harness.model.load(performLaunchSync: false)

        #expect(harness.model.startSleep(startedAt: initialStart))
        #expect(harness.model.startSleep(startedAt: initialStart.addingTimeInterval(600)) == false)

        #expect(hapticFeedbackProvider.events == [.sleepStarted, .actionFailed])
    }

    @Test
    func hardDeletePlaysDestructiveHaptic() async throws {
        let hapticFeedbackProvider = HapticFeedbackProviderSpy()
        let harness = try Harness(hapticFeedbackProvider: hapticFeedbackProvider)
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()

        harness.model.load(performLaunchSync: false)
        harness.model.nukeAllData()

        await Task.yield()

        #expect(hapticFeedbackProvider.events == [.destructiveActionConfirmed])
    }

    @Test
    func exportReadyPlaysSuccessHaptic() async throws {
        let hapticFeedbackProvider = HapticFeedbackProviderSpy()
        let harness = try Harness(hapticFeedbackProvider: hapticFeedbackProvider)
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()

        harness.model.load(performLaunchSync: false)
        harness.model.exportData()

        while true {
            switch harness.model.dataExportState {
            case .ready:
                #expect(hapticFeedbackProvider.events == [.actionSucceeded])
                return
            case .error(let message):
                Issue.record("Expected export to succeed, got error: \(message)")
                return
            case .idle, .exporting:
                await Task.yield()
            }
        }
    }

    @Test
    func failedSyncRefreshPlaysErrorHaptic() async throws {
        let hapticFeedbackProvider = HapticFeedbackProviderSpy()
        let syncEngine = TestSyncEngine()
        syncEngine.refreshForegroundSummary = SyncStatusSummary(
            state: .failed,
            pendingRecordCount: 0,
            lastSyncAt: nil,
            lastErrorDescription: "Sync unavailable. Sign in to iCloud."
        )
        let harness = try Harness(
            syncEngine: syncEngine,
            hapticFeedbackProvider: hapticFeedbackProvider
        )
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()
        harness.model.load(performLaunchSync: false)

        await harness.model.refreshSyncStatus()

        #expect(hapticFeedbackProvider.events.isEmpty)
    }

    @Test
    func shareSheetSaveFailureSuppressesUnavailableErrorBanner() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        harness.model.handleShareSheetSaveFailure(TestLocalizedError.accountUnavailable)

        #expect(harness.model.errorMessage == nil)
    }

    @Test
    func nappyMutationsKeepFeedFieldsStableAndUpdateNappyField() throws {
        let liveActivityManager = LiveActivityManagerSpy()
        let harness = try Harness(liveActivityManager: liveActivityManager)
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let feed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 120,
            occurredAt: Date(timeIntervalSince1970: 7_000),
            milkType: .formula
        )

        harness.model.load(performLaunchSync: false)

        let originalSnapshot = try #require(liveActivityManager.latestSnapshot)
        #expect(originalSnapshot.lastFeedAt == feed.metadata.occurredAt)

        #expect(
            harness.model.logNappy(
                type: .mixed,
                occurredAt: Date(timeIntervalSince1970: 7_500),
                pooVolume: .medium,
                pooColor: .brown
            )
        )
        #expect(liveActivityManager.latestSnapshot?.childID == originalSnapshot.childID)
        #expect(liveActivityManager.latestSnapshot?.lastFeedKind == originalSnapshot.lastFeedKind)
        #expect(liveActivityManager.latestSnapshot?.lastFeedAt == originalSnapshot.lastFeedAt)
        #expect(liveActivityManager.latestSnapshot?.lastNappyAt == Date(timeIntervalSince1970: 7_500))

        let loggedNappy = try #require(
            try harness.eventRepository.loadTimeline(
                for: seed.child.id,
                includingDeleted: false
            ).compactMap { event -> NappyEvent? in
                guard case let .nappy(nappy) = event else {
                    return nil
                }

                return nappy
            }.first
        )

        #expect(
            harness.model.updateNappy(
                id: loggedNappy.id,
                type: .poo,
                occurredAt: Date(timeIntervalSince1970: 7_800),
                pooVolume: .heavy,
                pooColor: .green
            )
        )
        #expect(liveActivityManager.latestSnapshot?.lastFeedAt == originalSnapshot.lastFeedAt)
        #expect(liveActivityManager.latestSnapshot?.lastNappyAt == Date(timeIntervalSince1970: 7_800))

        #expect(harness.model.deleteEvent(id: loggedNappy.id))
        #expect(liveActivityManager.latestSnapshot?.lastFeedAt == originalSnapshot.lastFeedAt)
        #expect(liveActivityManager.latestSnapshot?.lastNappyAt == nil)
    }

    @Test
    func selectingDifferentChildSynchronizesLiveActivityForSelectedChild() throws {
        let liveActivityManager = LiveActivityManagerSpy()
        let harness = try Harness(liveActivityManager: liveActivityManager)
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let secondChild = try harness.saveOwnedChild(
            name: "Juniper",
            owner: seed.localUser
        )

        _ = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 90,
            occurredAt: Date(timeIntervalSince1970: 5_000),
            milkType: nil
        )
        _ = try harness.saveBreastFeed(
            childID: secondChild.id,
            userID: seed.localUser.id,
            start: Date(timeIntervalSince1970: 5_500),
            end: Date(timeIntervalSince1970: 6_100),
            side: .left
        )

        harness.model.load(performLaunchSync: false)
        #expect(liveActivityManager.latestSnapshot?.childID == seed.child.id)

        harness.model.selectChild(id: secondChild.id)
        #expect(liveActivityManager.latestSnapshot?.childID == secondChild.id)
        #expect(liveActivityManager.latestSnapshot?.lastFeedKind == .breastFeed)
    }

    @Test
    func disablingLiveActivitiesEndsCurrentActivityAndPersistsPreference() throws {
        let liveActivityManager = LiveActivityManagerSpy()
        let preferenceStore = InMemoryLiveActivityPreferenceStore()
        let harness = try Harness(
            liveActivityManager: liveActivityManager,
            liveActivityPreferenceStore: preferenceStore
        )
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        _ = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 90,
            occurredAt: Date(timeIntervalSince1970: 5_000),
            milkType: nil
        )
        harness.model.load(performLaunchSync: false)
        #expect(liveActivityManager.latestSnapshot != nil)

        harness.model.setLiveActivitiesEnabled(false)

        #expect(harness.model.isLiveActivityEnabled == false)
        #expect(preferenceStore.isLiveActivityEnabled == false)
        #expect(liveActivityManager.latestSnapshot == nil)
    }

    @Test
    func disabledLiveActivitiesPreventNewSnapshotsDuringRefresh() throws {
        let liveActivityManager = LiveActivityManagerSpy()
        let preferenceStore = InMemoryLiveActivityPreferenceStore(isLiveActivityEnabled: false)
        let harness = try Harness(
            liveActivityManager: liveActivityManager,
            liveActivityPreferenceStore: preferenceStore
        )
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()
        harness.model.load(performLaunchSync: false)

        #expect(harness.model.isLiveActivityEnabled == false)
        #expect(liveActivityManager.latestSnapshot == nil)
        #expect(liveActivityManager.snapshots.count == 1)
    }

    @Test
    func syncRefreshReschedulesReminderNotificationsUsingRefreshedTimelineEvents() async throws {
        let notificationManager = LocalNotificationManagerSpy()
        let reminderPreferenceStore = InMemoryReminderNotificationPreferenceStore(
            isReminderNotificationsEnabled: true
        )
        let harness = try Harness(
            reminderNotificationPreferenceStore: reminderPreferenceStore,
            localNotificationManager: notificationManager
        )
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)
        let originalEventTime = try #require(calendar.date(byAdding: .hour, value: 8, to: today))
        let refreshedEventTime = try #require(calendar.date(byAdding: .hour, value: 10, to: today))

        _ = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 120,
            occurredAt: originalEventTime,
            milkType: nil
        )

        harness.model.load(performLaunchSync: false)
        await Task.yield()

        #expect(notificationManager.scheduledInactivityNotifications.count == 1)

        _ = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 150,
            occurredAt: refreshedEventTime,
            milkType: .formula
        )

        await harness.model.refreshSyncStatus()

        #expect(notificationManager.scheduledInactivityNotifications.count == 2)
        #expect(notificationManager.scheduledInactivityNotifications.last?.childID == seed.child.id)
        #expect(notificationManager.scheduledInactivityNotifications.last?.childName == seed.child.name)
    }

    @Test
    func updatingCurrentChildAdvancesUpdatedAt() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        harness.model.load(performLaunchSync: false)
        let originalChild = try #require(try harness.childRepository.loadChild(id: seed.child.id))

        harness.model.updateCurrentChild(
            name: "Poppy Updated",
            birthDate: nil,
            imageData: Data([0x01, 0x02])
        )

        let updatedChild = try #require(try harness.childRepository.loadChild(id: seed.child.id))
        #expect(updatedChild.name == "Poppy Updated")
        #expect(updatedChild.imageData == Data([0x01, 0x02]))
        #expect(updatedChild.updatedAt >= originalChild.updatedAt)
    }

    @Test
    func timelineBottleFeedTitlesRespectPreferredOunceUnit() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)
        let bottleTime = try #require(calendar.date(byAdding: .hour, value: 10, to: today))

        let bottleFeed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 150,
            occurredAt: bottleTime,
            milkType: .formula
        )

        harness.model.load(performLaunchSync: false)
        harness.model.updateCurrentChild(
            name: seed.child.name,
            birthDate: seed.child.birthDate,
            imageData: seed.child.imageData,
            preferredFeedVolumeUnit: .ounces
        )

        let items = selectedTimelineItems(
            pages: harness.model.timelinePages,
            selectedDay: harness.model.timelineSelectedDay
        )
        let bottleFeedItem = try #require(
            items.first(where: { $0.primaryEventID == bottleFeed.id })
        )

        #expect(bottleFeedItem.title == "5.1 oz")
    }

    // MARK: - Archive

    @Test
    func archiveChildRevokesActiveCaregivers() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let caregiver = try UserIdentity(displayName: "Jamie Caregiver")
        try harness.userIdentityRepository.saveUser(caregiver)
        try harness.membershipRepository.saveMembership(
            Membership(
                childID: seed.child.id,
                userID: caregiver.id,
                role: .caregiver,
                status: .active,
                invitedAt: .now,
                acceptedAt: .now
            )
        )

        harness.model.load(performLaunchSync: false)
        harness.model.archiveCurrentChild()

        let memberships = try harness.membershipRepository.loadMemberships(for: seed.child.id)
        let caregiverMembership = try #require(memberships.first { $0.userID == caregiver.id })
        #expect(caregiverMembership.status == .removed)
    }

    @Test
    func archiveChildIsUnavailableToCaregiver() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedActiveCaregiverProfile()
        harness.model.load(performLaunchSync: false)

        let membership = try #require(harness.model.currentMembership)
        #expect(ChildAccessPolicy.canPerform(.archiveChild, membership: membership) == false)
    }

    // MARK: - Hard Delete Child

    @Test
    func hardDeleteCurrentChildPurgesLocalData() async throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        _ = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 100,
            occurredAt: Date(timeIntervalSince1970: 1_000),
            milkType: nil
        )

        harness.model.load(performLaunchSync: false)
        harness.model.hardDeleteCurrentChild()
        await Task.yield()
        await Task.yield()

        let allChildren = try harness.childRepository.loadAllChildren()
        #expect(allChildren.isEmpty)
        #expect(harness.model.activeChildren.isEmpty)
        #expect(harness.model.localUser != nil, "User identity must be preserved after hard delete")
    }

    @Test
    func hardDeleteCurrentChildIsUnavailableToCaregiver() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        _ = try harness.seedActiveCaregiverProfile()
        harness.model.load(performLaunchSync: false)

        let membership = try #require(harness.model.currentMembership)
        #expect(ChildAccessPolicy.isActiveOwner(membership) == false)
    }

    @Test
    func hardDeleteCurrentChildDoesNotAffectOtherChildren() async throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let secondChild = try harness.saveOwnedChild(name: "Juniper", owner: seed.localUser)

        harness.model.load(performLaunchSync: false)
        harness.model.selectChild(id: seed.child.id)
        harness.model.hardDeleteCurrentChild()
        await Task.yield()
        await Task.yield()

        let remaining = try harness.childRepository.loadAllChildren()
        #expect(remaining.map(\.id) == [secondChild.id])
    }

    @Test
    func hardDeleteCurrentChildSelectsRemainingChildAndShowsSuccessMessage() async throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let secondChild = try harness.saveOwnedChild(name: "Juniper", owner: seed.localUser)

        harness.model.load(performLaunchSync: false)
        let previousResetToken = harness.model.navigationResetToken

        harness.model.selectChild(id: seed.child.id)
        harness.model.hardDeleteCurrentChild()
        await Task.yield()
        await Task.yield()

        #expect(harness.childSelectionStore.loadSelectedChildID() == secondChild.id)
        #expect(harness.model.currentChild?.id == secondChild.id)
        #expect(harness.model.route == .childProfile)
        #expect(harness.model.transientMessage == "Poppy deleted")
        #expect(harness.model.navigationResetToken == previousResetToken + 1)
    }

    @Test
    func beginAcceptingSharedChildShowsFullScreenLoadingState() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        harness.model.beginAcceptingSharedChild(childName: "Poppy")

        #expect(harness.model.shareAcceptanceLoadingState == .syncing(childName: "Poppy"))
    }

    @Test
    func completingSharedChildAcceptanceShowsCompletionStateWithContinueAction() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        _ = try harness.seedOwnerProfile()
        harness.model.beginAcceptingSharedChild(childName: "Poppy")

        harness.model.completeAcceptingSharedChild(childName: "Poppy")

        #expect(harness.model.shareAcceptanceLoadingState == .completed(childName: "Poppy"))
        #expect(harness.model.route == .childProfile)
        #expect(harness.model.currentChild?.name == "Poppy")

        harness.model.continueAfterAcceptingSharedChild()

        #expect(harness.model.shareAcceptanceLoadingState == nil)
        #expect(harness.model.route == .childProfile)
    }

    @Test
    func failingSharedChildAcceptanceClearsLoadingStateAndShowsError() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        harness.model.beginAcceptingSharedChild(childName: "Poppy")
        harness.model.failAcceptingSharedChild(TestSyncEngineError.unimplemented)

        #expect(harness.model.shareAcceptanceLoadingState == nil)
        #expect(harness.model.errorMessage == "Couldn't accept the shared child. Something went wrong. Please try again.")
    }

    // MARK: - Nuke All Data

    @Test
    func nukeAllDataRemovesAllOwnedChildrenLocally() async throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        _ = try harness.saveOwnedChild(name: "Juniper", owner: seed.localUser)

        harness.model.load(performLaunchSync: false)
        harness.model.nukeAllData()
        await Task.yield()
        await Task.yield()

        #expect(try harness.childRepository.loadAllChildren().isEmpty)
        #expect(harness.model.localUser == nil, "User identity must be wiped by nuke")
    }

    @Test
    func nukeAllDataRemovesCaregiverChildLocally() async throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedActiveCaregiverProfile()

        harness.model.load(performLaunchSync: false)
        harness.model.nukeAllData()
        await Task.yield()
        await Task.yield()

        // Caregiver's local view of the child is gone
        let childrenVisibleToCaregiver = try harness.childRepository.loadActiveChildren(
            for: seed.localUser.id
        )
        #expect(childrenVisibleToCaregiver.isEmpty)
        // The child record itself may still be in the store (owner's data),
        // but the caregiver's local identity and memberships are wiped.
        #expect(harness.model.localUser == nil)
    }

    private func selectedTimelineItems(
        pages: [TimelineDayGridPageState],
        selectedDay: Date
    ) -> [TimelineDayGridItemViewState] {
        let calendar = Calendar.autoupdatingCurrent
        let index = pages.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: selectedDay) }) ?? 0
        guard !pages.isEmpty else { return [] }
        guard let grid = pages[index].grid else { return [] }
        return grid.columns.flatMap(\.items)
    }

}

extension AppModelTests {
    @MainActor
    private struct Harness {
        let childRepository: InMemoryChildRepository
        let userIdentityRepository: InMemoryUserIdentityRepository
        let membershipRepository: InMemoryMembershipRepository
        let childSelectionStore: InMemoryChildSelectionStore
        let eventRepository: InMemoryEventRepository
        let syncEngine: any CloudKitSyncControlling
        let model: AppModel

        init(
            syncEngine: any CloudKitSyncControlling = TestSyncEngine(),
            liveActivityManager: any FeedLiveActivityManaging = NoOpFeedLiveActivityManager(),
            liveActivityPreferenceStore: any LiveActivityPreferenceStore = InMemoryLiveActivityPreferenceStore(),
            reminderNotificationPreferenceStore: any ReminderNotificationPreferenceStore = InMemoryReminderNotificationPreferenceStore(),
            localNotificationManager: any LocalNotificationManaging = NoOpLocalNotificationManager(),
            hapticFeedbackProvider: any HapticFeedbackProviding = NoOpHapticFeedbackProvider()
        ) throws {
            let store = InMemoryStore()
            self.childRepository = InMemoryChildRepository(store: store)
            self.userIdentityRepository = InMemoryUserIdentityRepository(store: store)
            self.membershipRepository = InMemoryMembershipRepository(store: store)
            self.childSelectionStore = InMemoryChildSelectionStore(store: store)
            self.eventRepository = InMemoryEventRepository(store: store)
            self.syncEngine = syncEngine
            self.model = AppModel(
                childRepository: childRepository,
                userIdentityRepository: userIdentityRepository,
                membershipRepository: membershipRepository,
                childSelectionStore: childSelectionStore,
                eventRepository: eventRepository,
                syncEngine: syncEngine,
                liveActivityManager: liveActivityManager,
                liveActivityPreferenceStore: liveActivityPreferenceStore,
                reminderNotificationPreferenceStore: reminderNotificationPreferenceStore,
                localNotificationManager: localNotificationManager,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
        }

        func cleanUp() {
            model.cancelPendingTasks()
        }

        func seedOwnerProfile() throws -> OwnerSeed {
            let owner = try UserIdentity(displayName: "Alex Parent")
            let child = try Child(name: "Poppy", createdBy: owner.id)

            try userIdentityRepository.saveLocalUser(owner)
            try childRepository.saveChild(child)
            try membershipRepository.saveMembership(
                .owner(
                    childID: child.id,
                    userID: owner.id,
                    createdAt: child.createdAt
                )
            )
            childSelectionStore.saveSelectedChildID(child.id)

            return OwnerSeed(localUser: owner, child: child)
        }

        func seedActiveCaregiverProfile() throws -> ActiveCaregiverSeed {
            let owner = try UserIdentity(displayName: "Sam Owner")
            let caregiver = try UserIdentity(displayName: "Jamie Caregiver")
            let child = try Child(name: "Robin", createdBy: owner.id)

            try userIdentityRepository.saveUser(owner)
            try userIdentityRepository.saveLocalUser(caregiver)
            try userIdentityRepository.saveUser(caregiver)
            try childRepository.saveChild(child)
            try membershipRepository.saveMembership(
                .owner(
                    childID: child.id,
                    userID: owner.id,
                    createdAt: child.createdAt
                )
            )
            try membershipRepository.saveMembership(
                Membership(
                    childID: child.id,
                    userID: caregiver.id,
                    role: .caregiver,
                    status: .active,
                    invitedAt: child.createdAt,
                    acceptedAt: child.createdAt
                )
            )
            childSelectionStore.saveSelectedChildID(child.id)

            return ActiveCaregiverSeed(
                owner: owner,
                localUser: caregiver,
                child: child
            )
        }

        func saveOwnedChild(
            name: String,
            owner: UserIdentity
        ) throws -> Child {
            let child = try Child(name: name, createdBy: owner.id)
            try childRepository.saveChild(child)
            try membershipRepository.saveMembership(
                .owner(
                    childID: child.id,
                    userID: owner.id,
                    createdAt: child.createdAt
                )
            )
            return child
        }

        func saveBreastFeed(
            childID: UUID,
            userID: UUID,
            start: Date,
            end: Date,
            side: BreastSide?
        ) throws -> BreastFeedEvent {
            let event = try BreastFeedEvent(
                metadata: EventMetadata(
                    childID: childID,
                    occurredAt: end,
                    createdAt: end,
                    createdBy: userID
                ),
                side: side,
                startedAt: start,
                endedAt: end
            )
            try eventRepository.saveEvent(.breastFeed(event))
            return event
        }

        func saveBottleFeed(
            childID: UUID,
            userID: UUID,
            amountMilliliters: Int,
            occurredAt: Date,
            milkType: MilkType?
        ) throws -> BottleFeedEvent {
            let event = try BottleFeedEvent(
                metadata: EventMetadata(
                    childID: childID,
                    occurredAt: occurredAt,
                    createdAt: occurredAt,
                    createdBy: userID
                ),
                amountMilliliters: amountMilliliters,
                milkType: milkType
            )
            try eventRepository.saveEvent(.bottleFeed(event))
            return event
        }

        func saveNappy(
            childID: UUID,
            userID: UUID,
            type: NappyType,
            occurredAt: Date,
            peeVolume: NappyVolume? = nil,
            pooVolume: NappyVolume? = nil,
            pooColor: PooColor?
        ) throws -> NappyEvent {
            let event = try NappyEvent(
                metadata: EventMetadata(
                    childID: childID,
                    occurredAt: occurredAt,
                    createdAt: occurredAt,
                    createdBy: userID
                ),
                type: type,
                peeVolume: peeVolume,
                pooVolume: pooVolume,
                pooColor: pooColor
            )
            try eventRepository.saveEvent(.nappy(event))
            return event
        }

        func saveSleep(
            childID: UUID,
            userID: UUID,
            startedAt: Date,
            endedAt: Date?
        ) throws -> SleepEvent {
            let occurredAt = endedAt ?? startedAt
            let event = try SleepEvent(
                metadata: EventMetadata(
                    childID: childID,
                    occurredAt: occurredAt,
                    createdAt: occurredAt,
                    createdBy: userID
                ),
                startedAt: startedAt,
                endedAt: endedAt
            )
            try eventRepository.saveEvent(.sleep(event))
            return event
        }
    }

    private struct OwnerSeed {
        let localUser: UserIdentity
        let child: Child
    }

    private struct ActiveCaregiverSeed {
        let owner: UserIdentity
        let localUser: UserIdentity
        let child: Child
    }

    @MainActor
    private final class LiveActivityManagerSpy: FeedLiveActivityManaging {
        var hasRunningActivity: Bool = false
        private(set) var snapshots: [FeedLiveActivitySnapshot?] = []
        private var _currentSnapshot: FeedLiveActivitySnapshot?

        var latestSnapshot: FeedLiveActivitySnapshot? {
            _currentSnapshot
        }

        func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
            snapshots.append(snapshot)
            _currentSnapshot = snapshot
        }
    }

    @MainActor
    private final class HapticFeedbackProviderSpy: HapticFeedbackProviding {
        private(set) var events: [HapticEvent] = []

        func play(_ event: HapticEvent) {
            events.append(event)
        }
    }

    @MainActor
    private final class LocalNotificationManagerSpy: LocalNotificationManaging {
        struct InactivityNotification: Equatable {
            let childID: UUID
            let childName: String
            let fireAfter: TimeInterval
        }

        private(set) var scheduledInactivityNotifications: [InactivityNotification] = []

        func isAuthorizedForNotifications() async -> Bool { true }
        func requestAuthorizationIfNeeded() async -> Bool { true }
        func scheduleRemoteSyncNotification(_ content: RemoteCaregiverNotificationContent) async {
            _ = content
        }

        func scheduleSleepDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async {
            _ = (childID, childName, fireAfter)
        }

        func cancelSleepDriftNotification(childID: UUID) async {
            _ = childID
        }

        func scheduleInactivityDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async {
            scheduledInactivityNotifications.append(
                InactivityNotification(
                    childID: childID,
                    childName: childName,
                    fireAfter: fireAfter
                )
            )
        }

        func cancelInactivityDriftNotification(childID: UUID) async {
            _ = childID
        }

        func pendingDriftNotifications() async -> [PendingDriftNotification] { [] }
    }
}

extension AppModelTests {
    @MainActor
    private final class TestSyncEngine: CloudKitSyncControlling {
        var statusSummary = SyncStatusSummary()
        var refreshForegroundSummary: SyncStatusSummary?

        func prepareForLaunch() async -> SyncStatusSummary {
            statusSummary
        }

        func refreshAfterLocalWrite() async -> SyncStatusSummary {
            statusSummary
        }

        func refreshForeground() async -> SyncStatusSummary {
            let summary = refreshForegroundSummary ?? statusSummary
            statusSummary = summary
            return summary
        }

        func forceFullRefresh() async -> SyncStatusSummary {
            let summary = refreshForegroundSummary ?? statusSummary
            statusSummary = summary
            return summary
        }

        func refreshAfterRemoteNotification() async -> SyncStatusSummary {
            statusSummary
        }

        func pendingInvites(for childID: UUID) -> [CloudKitPendingInvite] {
            []
        }

        func consumeRemoteCaregiverEventChanges() -> [RemoteCaregiverEventChange] {
            []
        }

        func prepareShare(for childID: UUID) async throws -> CloudKitSharePresentation {
            throw TestSyncEngineError.unimplemented
        }

        func removeParticipant(membership: Membership) async throws {}

        func loadPendingChangeCounts() throws -> [SyncRecordType: Int] {
            [:]
        }

        func leaveShare(childID: UUID) async throws {}

        func hardDeleteChildCloudData(childID: UUID) async throws {}
    }

    private enum TestSyncEngineError: Error {
        case unimplemented
    }

    private enum TestLocalizedError: LocalizedError {
        case accountUnavailable

        var errorDescription: String? {
            switch self {
            case .accountUnavailable:
                "Sync unavailable. Sign in to iCloud."
            }
        }
    }
}
