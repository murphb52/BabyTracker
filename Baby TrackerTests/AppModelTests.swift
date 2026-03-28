import BabyTrackerDomain
import BabyTrackerFeature
import BabyTrackerPersistence
import BabyTrackerSync
import Foundation
import Testing

@MainActor
struct AppModelTests {
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

        let profile = try #require(harness.model.profile)

        #expect(profile.home.recentEvents.count == 2)
        #expect(profile.home.recentEvents.map(\.id) == [laterFeed.id, earlierFeed.id])
        #expect(profile.home.recentEvents.first?.detailText == "150 mL • Formula")
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

        let profile = try #require(harness.model.profile)

        #expect(profile.eventHistory.events.count == 2)
        #expect(profile.eventHistory.events.map(\.id) == [laterNappy.id, earlierNappy.id])
        #expect(profile.eventHistory.events.first?.detailText == "Mixed • Poo: Heavy • Green")
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

        let profile = try #require(harness.model.profile)
        #expect(profile.home.recentEvents.count == 6)
        #expect(profile.eventHistory.events.count == 8)
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
        let profile = try #require(harness.model.profile)
        #expect(profile.availableChildren.map(\.child.id) == [seed.child.id, secondChild.id])
        #expect(profile.canCreateLocalChild)
    }

    @Test
    func timelineDerivesMixedDayBlocksOldestFirstWithSideBySideLayout() throws {
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

        let timeline = try #require(harness.model.profile?.timeline)
        let blocks = selectedTimelineBlocks(in: timeline)
        let firstWeekday = Calendar.autoupdatingCurrent.component(
            .weekday,
            from: try #require(timeline.pages.first?.date)
        )

        #expect(blocks.map(\.id) == [breastFeed.id, sleep.id, bottleFeed.id, nappy.id])
        #expect(timeline.pages.count == 7)
        #expect(firstWeekday == 2)
        #expect(blocks[0].startMinute == 360)
        #expect(blocks[0].endMinute == 380)
        #expect(blocks[0].compactText == "20 min")
        #expect(blocks[1].startMinute == 540)
        #expect(blocks[1].endMinute == 660)
        #expect(blocks[1].laneCount == 2)
        #expect(blocks[1].compactText == "120 min")
        #expect(blocks[2].laneIndex == 1)
        #expect(blocks[2].laneCount == 2)
        #expect(blocks[2].compactText == "150 mL")
        #expect(blocks[3].compactText == "Mixed")
        #expect(blocks[2].actionPayload == .editBottleFeed(
            amountMilliliters: 150,
            occurredAt: bottleTime,
            milkType: .formula
        ))
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

        var timeline = try #require(harness.model.profile?.timeline)
        #expect(selectedTimelineBlocks(in: timeline).map(\.id) == [todayEvent.id])
        #expect(timeline.canMoveToNextDay == true)
        #expect(timeline.showsJumpToToday == false)
        #expect(timeline.pages.count == 7)

        harness.model.showPreviousTimelineDay()

        timeline = try #require(harness.model.profile?.timeline)
        #expect(selectedTimelineBlocks(in: timeline).map(\.id) == [yesterdayEvent.id])
        #expect(timeline.canMoveToNextDay)
        #expect(timeline.showsJumpToToday)

        harness.model.showNextTimelineDay()

        timeline = try #require(harness.model.profile?.timeline)
        #expect(selectedTimelineBlocks(in: timeline).map(\.id) == [todayEvent.id])
        #expect(timeline.canMoveToNextDay == true)
    }

    @Test
    func activeSleepAppearsOnTimelineWithEndAction() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)
        let start = try #require(calendar.date(byAdding: .hour, value: 7, to: today))

        let activeSleep = try harness.saveSleep(
            childID: seed.child.id,
            userID: seed.localUser.id,
            startedAt: start,
            endedAt: nil
        )

        harness.model.load(performLaunchSync: false)

        let timeline = try #require(harness.model.profile?.timeline)
        let block = try #require(
            selectedTimelineBlocks(in: timeline).first(where: { $0.id == activeSleep.id })
        )

        #expect(block.startMinute == 420)
        #expect(block.endMinute > block.startMinute)
        #expect(block.actionPayload == .endSleep(startedAt: start))
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

        let timeline = try #require(harness.model.profile?.timeline)

        #expect(Calendar.autoupdatingCurrent.isDateInToday(timeline.selectedDay))
        #expect(timeline.canMoveToNextDay == true)
        #expect(timeline.showsJumpToToday == false)
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

        let profile = try #require(harness.model.profile)

        #expect(profile.cloudKitStatus.state == .failed)
        #expect(profile.timeline.syncMessage == profile.cloudKitStatus.detailMessage)
    }

    @Test
    func syncIndicatorShowsTransientUnavailableStateAfterFailedRefresh() async throws {
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

        guard let syncBannerState = harness.model.syncBannerState else {
            Issue.record("Expected sync banner state after refresh")
            return
        }

        switch syncBannerState {
        case let .syncUnavailable(message):
            #expect(message.localizedCaseInsensitiveContains("sync unavailable"))
        case let .lastSyncFailed(message):
            #expect(message.isEmpty == false)
        case .syncing, .pendingSync:
            Issue.record("Expected failed sync banner state after refresh completed")
        }
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

        let timeline = try #require(harness.model.profile?.timeline)
        let todayColumn = try #require(timeline.stripColumns.last(where: { $0.isToday }))
        let tenAMSlot = (10 * 60) / BuildTimelineStripDatasetUseCase.defaultSlotMinutes

        #expect(timeline.displayMode == .week)
        #expect(timeline.stripColumns.count >= 7)
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

        let profile = try #require(harness.model.profile)
        #expect(profile.home.currentSleep == nil)
        #expect(profile.home.currentStatus.timeSinceLastFeedAt == feed.metadata.occurredAt)
        #expect(profile.home.currentStatus.timeSinceLastNappyAt == nil)
        #expect(profile.home.recentEvents.map(\.id) == [sleep.id, feed.id])
        #expect(
            liveActivityManager.latestSnapshot == FeedLiveActivitySnapshot(
                childID: seed.child.id,
                childName: seed.child.name,
                lastFeedKind: .bottleFeed,
                lastFeedAt: feed.metadata.occurredAt
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

        let profile = try #require(harness.model.profile)

        #expect(profile.home.currentStatus.timeSinceLastFeedAt == latestFeed.metadata.occurredAt)
        #expect(profile.home.currentStatus.feedsTodayCount == 2)
        #expect(profile.home.currentStatus.timeSinceLastNappyAt == latestNappy.metadata.occurredAt)
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

        let profile = try #require(harness.model.profile)
        #expect(profile.canManageEvents)

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

        let profile = try #require(harness.model.profile)
        #expect(profile.canLogEvents)
        #expect(profile.canManageEvents)

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

        var profile = try #require(harness.model.profile)
        let activeSleep = try #require(profile.activeSleepSession)
        let currentSleep = try #require(profile.home.currentSleep)

        #expect(activeSleep.startedAt == sleepStart)
        #expect(currentSleep.startedAt == sleepStart)
        #expect(currentSleep.sleepEventID == activeSleep.id)
        #expect(profile.home.recentEvents.map(\.id) == [activeSleep.id])

        harness.model.load(performLaunchSync: false)

        profile = try #require(harness.model.profile)
        let recoveredSleep = try #require(profile.activeSleepSession)
        #expect(recoveredSleep.id == activeSleep.id)

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

        profile = try #require(harness.model.profile)
        #expect(profile.activeSleepSession == nil)
        #expect(profile.home.recentEvents.map(\.id) == [recoveredSleep.id])
        #expect(profile.home.currentSleep == nil)

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
    func sleepMutationsDoNotChangeLiveActivityFeedSnapshot() throws {
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
        #expect(liveActivityManager.latestSnapshot == originalSnapshot)

        let activeSleep = try #require(harness.model.profile?.activeSleepSession)

        #expect(
            harness.model.endSleep(
                id: activeSleep.id,
                startedAt: activeSleep.startedAt,
                endedAt: Date(timeIntervalSince1970: 12_100)
            )
        )
        #expect(liveActivityManager.latestSnapshot == originalSnapshot)

        #expect(
            harness.model.updateSleep(
                id: activeSleep.id,
                startedAt: Date(timeIntervalSince1970: 11_600),
                endedAt: Date(timeIntervalSince1970: 12_300)
            )
        )
        #expect(liveActivityManager.latestSnapshot == originalSnapshot)

        #expect(harness.model.deleteEvent(id: activeSleep.id))
        #expect(liveActivityManager.latestSnapshot == originalSnapshot)
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
        harness.model.hardDeleteAllData()

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

        #expect(hapticFeedbackProvider.events == [.actionFailed])
    }

    @Test
    func nappyMutationsDoNotChangeLiveActivityFeedSnapshot() throws {
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
        #expect(liveActivityManager.latestSnapshot == originalSnapshot)

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
        #expect(liveActivityManager.latestSnapshot == originalSnapshot)

        #expect(harness.model.deleteEvent(id: loggedNappy.id))
        #expect(liveActivityManager.latestSnapshot == originalSnapshot)
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

    private func selectedTimelineBlocks(
        in timeline: TimelineScreenState
    ) -> [TimelineEventBlockViewState] {
        timeline.pages[timeline.selectedPageIndex].blocks
    }

}

extension AppModelTests {
    @MainActor
    private struct Harness {
        let suiteName = "BabyTrackerAppModelTests.\(UUID().uuidString)"
        let userDefaults: UserDefaults
        let store: BabyTrackerModelStore
        let childRepository: SwiftDataChildRepository
        let userIdentityRepository: SwiftDataUserIdentityRepository
        let membershipRepository: SwiftDataMembershipRepository
        let childSelectionStore: UserDefaultsChildSelectionStore
        let eventRepository: SwiftDataEventRepository
        let syncEngine: any CloudKitSyncControlling
        let model: AppModel

        init(
            syncEngine: any CloudKitSyncControlling = TestSyncEngine(),
            liveActivityManager: any FeedLiveActivityManaging = NoOpFeedLiveActivityManager(),
            hapticFeedbackProvider: any HapticFeedbackProviding = NoOpHapticFeedbackProvider()
        ) throws {
            let userDefaults = UserDefaults(suiteName: suiteName)!
            userDefaults.removePersistentDomain(forName: suiteName)

            self.userDefaults = userDefaults
            self.store = try BabyTrackerModelStore(isStoredInMemoryOnly: true)
            self.childRepository = SwiftDataChildRepository(store: store)
            self.userIdentityRepository = SwiftDataUserIdentityRepository(store: store, userDefaults: userDefaults)
            self.membershipRepository = SwiftDataMembershipRepository(store: store)
            self.childSelectionStore = UserDefaultsChildSelectionStore(userDefaults: userDefaults)
            self.eventRepository = SwiftDataEventRepository(store: store)
            self.syncEngine = syncEngine
            self.model = AppModel(
                childRepository: childRepository,
                userIdentityRepository: userIdentityRepository,
                membershipRepository: membershipRepository,
                childSelectionStore: childSelectionStore,
                eventRepository: eventRepository,
                syncEngine: syncEngine,
                liveActivityManager: liveActivityManager,
                hapticFeedbackProvider: hapticFeedbackProvider
            )
        }

        func cleanUp() {
            userDefaults.removePersistentDomain(forName: suiteName)
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
        private(set) var snapshots: [FeedLiveActivitySnapshot?] = []

        var latestSnapshot: FeedLiveActivitySnapshot? {
            snapshots.last ?? nil
        }

        func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
            snapshots.append(snapshot)
        }
    }

    @MainActor
    private final class HapticFeedbackProviderSpy: HapticFeedbackProviding {
        private(set) var events: [HapticEvent] = []

        func play(_ event: HapticEvent) {
            events.append(event)
        }
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

        func hardDeleteAllCloudData() async throws {}
    }

    private enum TestSyncEngineError: Error {
        case unimplemented
    }
}
