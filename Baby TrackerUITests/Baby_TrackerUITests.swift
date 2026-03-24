import XCTest

final class Baby_TrackerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFirstLaunchFlowsIntoChildProfile() throws {
        throw XCTSkip("Needs to be revisited.")
        let app = makeApp()
        app.launch()

        let identityField = app.textFields["identity-name-field"]
        XCTAssertTrue(identityField.waitForExistence(timeout: 5))
        identityField.tap()
        identityField.typeText("Alex Parent")
        app.buttons["identity-save-button"].tap()

        let childField = app.textFields["child-name-field"]
        XCTAssertTrue(childField.waitForExistence(timeout: 5))
        childField.tap()
        childField.typeText("Poppy")
        app.buttons["create-child-button"].tap()

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["quick-log-breast-feed-button"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOwnerSeesStage2SharingUIWithoutActivationControls() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        openProfileTab(in: app)
        tapProfileRow(named: "Sharing", in: app)
        let activeCaregiversHeader = app.staticTexts["Active Caregivers"]
        let removedCaregiversHeader = app.staticTexts["Removed Caregivers"]

        scrollToElement(activeCaregiversHeader, in: app)
        scrollToElement(removedCaregiversHeader, in: app)

        XCTAssertTrue(activeCaregiversHeader.exists)
        XCTAssertTrue(removedCaregiversHeader.exists)

        let shareButton = app.buttons["share-child-button"]
        XCTAssertTrue(shareButton.exists)
        XCTAssertFalse(app.buttons["Mark Active"].exists)
        XCTAssertFalse(app.buttons["invite-caregiver-button"].exists)
    }

    @MainActor
    func testOwnerCanArchiveAndRestoreOnlyChild() throws {
        throw XCTSkip("Needs to be revisited.")
        let app = launchOwnerFlow()
        openProfileTab(in: app)
        tapProfileRow(named: "Archive Child", in: app)

        let archiveButton = app.buttons["archive-child-button"]
        XCTAssertTrue(archiveButton.waitForExistence(timeout: 5))

        archiveButton.tap()

        let restoreButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Restore ")
        ).firstMatch
        scrollToElement(restoreButton, in: app, maxSwipes: 10)
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 5))
        restoreButton.tap()

        openProfileTab(in: app)
        tapProfileRow(named: "Details", in: app)

        let profileName = app.staticTexts["child-profile-name"]
        scrollToElement(profileName, in: app)
        XCTAssertTrue(profileName.exists)
    }

    @MainActor
    func testOwnerCanQuickLogBreastFeed() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        XCTAssertTrue(app.buttons["quick-log-breast-feed-button"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["current-status-empty-state"].exists)

        app.buttons["quick-log-breast-feed-button"].tap()

        let saveButton = app.buttons["save-breast-feed-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        let latestFeedValue = app.staticTexts["current-status-last-event-value"]
        XCTAssertTrue(latestFeedValue.waitForExistence(timeout: 5))
        XCTAssertEqual(latestFeedValue.label, "Breast Feed")
        XCTAssertEqual(app.staticTexts["current-status-feeds-today-value"].label, "1")
    }

    @MainActor
    func testOwnerCanQuickLogBottleFeedWithoutMilkType() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        XCTAssertTrue(app.buttons["quick-log-bottle-feed-button"].waitForExistence(timeout: 5))

        app.buttons["quick-log-bottle-feed-button"].tap()

        let saveButton = app.buttons["save-bottle-feed-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        let latestFeedValue = app.staticTexts["current-status-last-event-value"]
        XCTAssertTrue(latestFeedValue.waitForExistence(timeout: 5))
        XCTAssertEqual(latestFeedValue.label, "Bottle Feed")
        XCTAssertEqual(app.staticTexts["current-status-feeds-today-value"].label, "1")
    }

    @MainActor
    func testOwnerCanQuickLogNappy() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        selectNappyType("Poo", in: app)

        let saveButton = app.buttons["save-nappy-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        let latestEventValue = app.staticTexts["current-status-last-event-value"]
        XCTAssertTrue(latestEventValue.waitForExistence(timeout: 5))
        XCTAssertEqual(latestEventValue.label, "Nappy")
        XCTAssertTrue(app.staticTexts["current-status-last-nappy-value"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOwnerCanStartAndEndSleep() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        let sleepButton = app.buttons["quick-log-sleep-button"]
        XCTAssertTrue(sleepButton.waitForExistence(timeout: 5))
        XCTAssertEqual(sleepButton.label, "Start Sleep")

        sleepButton.tap()

        let saveButton = app.buttons["save-sleep-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        XCTAssertEqual(app.buttons["quick-log-sleep-button"].label, "End Sleep")
        XCTAssertEqual(app.staticTexts["current-status-last-sleep-value"].label, "In progress")

        app.buttons["quick-log-sleep-button"].tap()
        XCTAssertTrue(app.buttons["save-sleep-button"].waitForExistence(timeout: 5))
        app.buttons["save-sleep-button"].tap()

        openEventsTab(in: app)

        let recentSleepButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "event-history-event-")
        ).firstMatch
        XCTAssertTrue(recentSleepButton.waitForExistence(timeout: 5))
        openHomeTab(in: app)
        XCTAssertEqual(app.buttons["quick-log-sleep-button"].label, "Start Sleep")
    }

    @MainActor
    func testSleepEndSheetDefaultsToValidEndTime() throws {
        let app = makeApp(scenario: "futureActiveSleepPreview")
        app.launch()

        let sleepButton = app.buttons["quick-log-sleep-button"]
        XCTAssertTrue(sleepButton.waitForExistence(timeout: 5))
        XCTAssertEqual(sleepButton.label, "End Sleep")

        sleepButton.tap()

        let saveButton = app.buttons["save-sleep-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        XCTAssertTrue(saveButton.isEnabled)
        XCTAssertFalse(app.staticTexts["End time must be later than the start time."].exists)
    }

    @MainActor
    func testOwnerCanOpenEditSleepFlowFromRecentSleep() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        createCompletedSleep(in: app)
        openEventsTab(in: app)

        let recentSleepButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "event-history-event-")
        ).firstMatch
        XCTAssertTrue(recentSleepButton.waitForExistence(timeout: 5))
        recentSleepButton.swipeRight()
        app.buttons["Edit"].tap()

        let saveButton = app.buttons["save-sleep-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        XCTAssertTrue(recentSleepButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testDeleteRequiresConfirmationAndUndoRestoresSleep() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        createCompletedSleep(in: app)
        openEventsTab(in: app)

        let recentSleepButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "event-history-event-")
        ).firstMatch
        XCTAssertTrue(recentSleepButton.waitForExistence(timeout: 5))
        recentSleepButton.swipeLeft()
        app.buttons["Delete"].tap()

        let confirmDeleteButton = app.buttons["Delete Sleep"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 5))
        confirmDeleteButton.tap()

        let undoButton = app.buttons["undo-delete-button"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["event-history-empty-state"].exists)

        undoButton.tap()

        XCTAssertTrue(recentSleepButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testActiveSleepCanBeDeletedFromEndSheet() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        let sleepButton = app.buttons["quick-log-sleep-button"]
        XCTAssertTrue(sleepButton.waitForExistence(timeout: 5))
        sleepButton.tap()
        XCTAssertTrue(app.buttons["save-sleep-button"].waitForExistence(timeout: 5))
        app.buttons["save-sleep-button"].tap()

        XCTAssertEqual(app.buttons["quick-log-sleep-button"].label, "End Sleep")

        app.buttons["quick-log-sleep-button"].tap()
        let deleteButton = app.buttons["delete-sleep-button"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        let undoButton = app.buttons["undo-delete-button"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["quick-log-sleep-button"].label, "Start Sleep")
        undoButton.tap()
        XCTAssertEqual(app.buttons["quick-log-sleep-button"].label, "End Sleep")
    }

    @MainActor
    func testNappyQuickLogShowsPooColorOnlyForPooCapableTypes() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        selectNappyType("Dry", in: app)

        XCTAssertTrue(app.buttons["save-nappy-button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["nappy-poo-color-picker"].exists)
        app.buttons["Cancel"].tap()

        selectNappyType("Mixed", in: app)

        XCTAssertTrue(app.buttons["nappy-poo-color-picker"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testActiveCaregiverDoesNotSeeOwnerActions() throws {
        let app = makeApp(scenario: "activeCaregiver")
        app.launch()

        XCTAssertTrue(app.buttons["quick-log-bottle-feed-button"].waitForExistence(timeout: 5))
        openProfileTab(in: app)
        tapProfileRow(named: "Details", in: app)
        XCTAssertFalse(app.buttons["edit-child-button"].exists)
        navigateBack(in: app)

        tapProfileRow(named: "Sharing", in: app)
        XCTAssertFalse(app.buttons["share-child-button"].exists)
        navigateBack(in: app)

        XCTAssertFalse(app.staticTexts["Archive Child"].exists)
    }

    @MainActor
    func testActiveCaregiverCanQuickLogBottleFeed() throws {
        let app = makeApp(scenario: "activeCaregiver")
        app.launch()

        XCTAssertTrue(app.buttons["quick-log-bottle-feed-button"].waitForExistence(timeout: 5))

        app.buttons["quick-log-bottle-feed-button"].tap()

        let saveButton = app.buttons["save-bottle-feed-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        let latestFeedValue = app.staticTexts["current-status-last-event-value"]
        XCTAssertTrue(latestFeedValue.waitForExistence(timeout: 5))
        XCTAssertEqual(latestFeedValue.label, "Bottle Feed")
    }

    @MainActor
    func testInvalidBreastFeedDurationDisablesSave() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        XCTAssertTrue(app.buttons["quick-log-breast-feed-button"].waitForExistence(timeout: 5))
        app.buttons["quick-log-breast-feed-button"].tap()

        let durationField = app.textFields["breast-feed-duration-field"]
        XCTAssertTrue(durationField.waitForExistence(timeout: 5))
        replaceText(in: durationField, with: "0")

        let saveButton = app.buttons["save-breast-feed-button"]
        XCTAssertTrue(saveButton.exists)
        XCTAssertFalse(saveButton.isEnabled)
        XCTAssertTrue(app.staticTexts["Enter a duration greater than 0 minutes."].exists)
    }

    @MainActor
    func testBreastFeedQuickDurationPresetUpdatesField() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        app.buttons["quick-log-breast-feed-button"].tap()

        let durationField = app.textFields["breast-feed-duration-field"]
        XCTAssertTrue(durationField.waitForExistence(timeout: 5))

        app.buttons["breast-feed-duration-preset-5"].tap()

        XCTAssertEqual(durationField.value as? String, "5")
    }

    @MainActor
    func testOwnerCanEditBreastFeedFromRecentFeeds() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        app.buttons["quick-log-breast-feed-button"].tap()
        XCTAssertTrue(app.buttons["save-breast-feed-button"].waitForExistence(timeout: 5))
        app.buttons["save-breast-feed-button"].tap()
        openEventsTab(in: app)

        let recentFeedButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "event-history-event-")
        ).firstMatch
        XCTAssertTrue(recentFeedButton.waitForExistence(timeout: 5))
        recentFeedButton.swipeRight()
        app.buttons["Edit"].tap()

        let durationField = app.textFields["breast-feed-duration-field"]
        XCTAssertTrue(durationField.waitForExistence(timeout: 5))
        replaceText(in: durationField, with: "20")

        app.buttons["save-breast-feed-button"].tap()

        XCTAssertTrue(app.staticTexts["20 min"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testActiveCaregiverCanEditBottleFeedFromRecentFeeds() throws {
        let app = makeApp(scenario: "activeCaregiver")
        app.launch()

        app.buttons["quick-log-bottle-feed-button"].tap()
        XCTAssertTrue(app.buttons["save-bottle-feed-button"].waitForExistence(timeout: 5))
        app.buttons["save-bottle-feed-button"].tap()
        openEventsTab(in: app)

        let recentFeedButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "event-history-event-")
        ).firstMatch
        XCTAssertTrue(recentFeedButton.waitForExistence(timeout: 5))
        recentFeedButton.swipeRight()
        app.buttons["Edit"].tap()

        let amountField = app.textFields["bottle-feed-amount-field"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 5))
        replaceText(in: amountField, with: "150")

        app.buttons["save-bottle-feed-button"].tap()

        XCTAssertTrue(app.staticTexts["150 mL"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testBottleFeedQuickAmountPresetUpdatesField() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        app.buttons["quick-log-bottle-feed-button"].tap()

        let amountField = app.textFields["bottle-feed-amount-field"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 5))

        app.buttons["bottle-feed-amount-preset-70"].tap()

        XCTAssertEqual(amountField.value as? String, "70")
    }

    @MainActor
    func testDeleteRequiresConfirmationAndUndoRestoresFeed() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        app.buttons["quick-log-bottle-feed-button"].tap()
        XCTAssertTrue(app.buttons["save-bottle-feed-button"].waitForExistence(timeout: 5))
        app.buttons["save-bottle-feed-button"].tap()
        openEventsTab(in: app)

        let recentFeedButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "event-history-event-")
        ).firstMatch
        XCTAssertTrue(recentFeedButton.waitForExistence(timeout: 5))
        recentFeedButton.swipeLeft()
        app.buttons["Delete"].tap()

        let confirmDeleteButton = app.buttons["Delete Feed"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 5))
        confirmDeleteButton.tap()

        let undoButton = app.buttons["undo-delete-button"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["event-history-empty-state"].exists)

        undoButton.tap()

        XCTAssertTrue(recentFeedButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testDeleteRequiresConfirmationAndUndoRestoresNappy() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        selectNappyType("Mixed", in: app)
        XCTAssertTrue(app.buttons["save-nappy-button"].waitForExistence(timeout: 5))
        app.buttons["save-nappy-button"].tap()
        openEventsTab(in: app)

        let recentNappyButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "event-history-event-")
        ).firstMatch
        XCTAssertTrue(recentNappyButton.waitForExistence(timeout: 5))
        recentNappyButton.swipeLeft()
        app.buttons["Delete"].tap()

        let confirmDeleteButton = app.buttons["Delete Nappy"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 5))
        confirmDeleteButton.tap()

        let undoButton = app.buttons["undo-delete-button"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["event-history-empty-state"].exists)

        undoButton.tap()

        XCTAssertTrue(recentNappyButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testHomeDoesNotShowRecentActivitySection() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        XCTAssertTrue(app.staticTexts["Current Status"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Recent Activity"].exists)
        XCTAssertFalse(app.staticTexts["home-recent-events-empty-state"].exists)
    }

    @MainActor
    func testMixedEventsScenarioShowsLatestEventInCurrentStatus() throws {
        let app = makeApp(scenario: "mixedEventsPreview")
        app.launch()

        XCTAssertTrue(app.staticTexts["current-status-last-event-value"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["current-status-last-event-value"].label, "Sleep")
        XCTAssertEqual(app.staticTexts["current-status-last-event-detail"].label, "30 min")
        XCTAssertEqual(app.staticTexts["current-status-feeds-today-value"].label, "1")
        XCTAssertFalse(app.staticTexts["current-status-since-last-feed-value"].label.isEmpty)
        XCTAssertFalse(app.staticTexts["Recent Activity"].exists)
    }

    @MainActor
    func testTimelineScreenShowsEmptyStateForOwnerPreview() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        openTimelineTab(in: app)

        XCTAssertTrue(app.staticTexts["timeline-empty-state"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTimelineDayNavigationCanReturnToToday() throws {
        let app = makeApp(scenario: "mixedEventsPreview")
        app.launch()

        openTimelineTab(in: app)

        let timelineScrollView = app.scrollViews["timeline-scroll-view"]
        XCTAssertTrue(timelineScrollView.waitForExistence(timeout: 5))

        let todayTitle = app.staticTexts["timeline-day-title"]
        XCTAssertTrue(todayTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(todayTitle.label, "Today")

        let jumpToTodayButton = app.buttons["timeline-jump-to-today-button"]
        XCTAssertTrue(jumpToTodayButton.waitForExistence(timeout: 5))
        XCTAssertFalse(jumpToTodayButton.isEnabled)

        let sundayButton = app.buttons["timeline-weekday-0"]
        XCTAssertTrue(sundayButton.waitForExistence(timeout: 5))

        timelineScrollView.swipeRight()

        XCTAssertTrue(app.staticTexts["timeline-empty-state"].waitForExistence(timeout: 5))
        XCTAssertTrue(jumpToTodayButton.isEnabled)

        timelineScrollView.swipeLeft()

        XCTAssertEqual(app.staticTexts["timeline-day-title"].label, "Today")
        XCTAssertFalse(jumpToTodayButton.isEnabled)
        XCTAssertTrue(
            app.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH %@", "timeline-event-")
            ).firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testTimelineDayPickerCanJumpBackToToday() throws {
        let app = makeApp(scenario: "mixedEventsPreview")
        app.launch()

        openTimelineTab(in: app)

        let timelineScrollView = app.scrollViews["timeline-scroll-view"]
        XCTAssertTrue(timelineScrollView.waitForExistence(timeout: 5))
        timelineScrollView.swipeRight()

        XCTAssertTrue(app.buttons["timeline-jump-to-today-button"].waitForExistence(timeout: 5))

        app.buttons["timeline-day-picker-button"].tap()

        let dayPicker = app.datePickers["timeline-day-picker"]
        XCTAssertTrue(dayPicker.waitForExistence(timeout: 5))

        app.buttons["timeline-day-picker-today-button"].tap()

        XCTAssertEqual(app.staticTexts["timeline-day-title"].label, "Today")
    }

    @MainActor
    func testTimelineBottleFeedRowOpensEditFlow() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        app.buttons["quick-log-bottle-feed-button"].tap()
        XCTAssertTrue(app.buttons["save-bottle-feed-button"].waitForExistence(timeout: 5))
        app.buttons["save-bottle-feed-button"].tap()

        openTimelineTab(in: app)

        let timelineEvent = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "timeline-event-")
        ).firstMatch
        XCTAssertTrue(timelineEvent.waitForExistence(timeout: 5))
        timelineEvent.tap()

        XCTAssertTrue(app.buttons["save-bottle-feed-button"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTimelineActiveSleepRowOpensEndSleepFlow() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        let sleepButton = app.buttons["quick-log-sleep-button"]
        XCTAssertTrue(sleepButton.waitForExistence(timeout: 5))
        sleepButton.tap()
        XCTAssertTrue(app.buttons["save-sleep-button"].waitForExistence(timeout: 5))
        app.buttons["save-sleep-button"].tap()

        openTimelineTab(in: app)

        let activeSleepEvent = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "timeline-event-")
        ).firstMatch
        XCTAssertTrue(activeSleepEvent.waitForExistence(timeout: 5))
        activeSleepEvent.tap()

        XCTAssertTrue(app.buttons["save-sleep-button"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTimelineDeleteShowsUndoAndRemovesRow() throws {
        throw XCTSkip("Timeline block context menus are not surfaced reliably by XCTest on the iOS 26.2 simulator.")

        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        app.buttons["quick-log-bottle-feed-button"].tap()
        XCTAssertTrue(app.buttons["save-bottle-feed-button"].waitForExistence(timeout: 5))
        app.buttons["save-bottle-feed-button"].tap()

        openTimelineTab(in: app)

        let timelineEvent = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "timeline-event-")
        ).firstMatch
        XCTAssertTrue(timelineEvent.waitForExistence(timeout: 5))
        timelineEvent.press(forDuration: 1.0)
        tapDeleteContextAction(in: app)

        let confirmDeleteButton = app.buttons["Delete Feed"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 5))
        confirmDeleteButton.tap()

        let undoButton = app.buttons["undo-delete-button"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["timeline-empty-state"].waitForExistence(timeout: 5))

        undoButton.tap()

        XCTAssertTrue(timelineEvent.waitForExistence(timeout: 5))
    }

    @MainActor
    private func launchOwnerFlow() -> XCUIApplication {
        let app = makeApp()
        app.launch()

        let identityField = app.textFields["identity-name-field"]
        XCTAssertTrue(identityField.waitForExistence(timeout: 5))
        identityField.tap()
        identityField.typeText("Alex Parent")
        app.buttons["identity-save-button"].tap()

        let childField = app.textFields["child-name-field"]
        XCTAssertTrue(childField.waitForExistence(timeout: 5))
        childField.tap()
        childField.typeText("Poppy")
        app.buttons["create-child-button"].tap()

        XCTAssertTrue(app.buttons["quick-log-breast-feed-button"].waitForExistence(timeout: 5))

        return app
    }

    @MainActor
    private func replaceText(in element: XCUIElement, with value: String) {
        element.tap()

        if let existingValue = element.value as? String {
            let deleteText = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count)
            element.typeText(deleteText)
        }

        element.typeText(value)
    }

    @MainActor
    private func scrollToElement(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maxSwipes: Int = 5
    ) {
        for _ in 0..<maxSwipes where !element.exists || !element.isHittable {
            app.swipeUp()
        }
    }

    @MainActor
    private func makeApp(scenario: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["UI_TESTING"]

        if let scenario {
            app.launchEnvironment["UI_TEST_SCENARIO"] = scenario
        }

        return app
    }

    @MainActor
    private func createCompletedSleep(in app: XCUIApplication) {
        let sleepButton = app.buttons["quick-log-sleep-button"]
        XCTAssertTrue(sleepButton.waitForExistence(timeout: 5))

        sleepButton.tap()
        XCTAssertTrue(app.buttons["save-sleep-button"].waitForExistence(timeout: 5))
        app.buttons["save-sleep-button"].tap()

        XCTAssertEqual(app.buttons["quick-log-sleep-button"].label, "End Sleep")

        app.buttons["quick-log-sleep-button"].tap()
        XCTAssertTrue(app.buttons["save-sleep-button"].waitForExistence(timeout: 5))
        app.buttons["save-sleep-button"].tap()
    }

    @MainActor
    private func openTimelineTab(in app: XCUIApplication) {
        let timelineTab = app.tabBars.buttons["Timeline"]
        XCTAssertTrue(timelineTab.waitForExistence(timeout: 5))
        timelineTab.tap()
    }

    @MainActor
    private func openHomeTab(in app: XCUIApplication) {
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        homeTab.tap()
    }

    @MainActor
    private func openEventsTab(in app: XCUIApplication) {
        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()
    }

    @MainActor
    private func openProfileTab(in app: XCUIApplication) {
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5))
        profileTab.tap()
    }

    @MainActor
    private func tapProfileRow(named label: String, in app: XCUIApplication) {
        let row = app.cells.containing(.staticText, identifier: label).firstMatch
        if row.waitForExistence(timeout: 5) {
            row.tap()
            return
        }

        let button = app.buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }

    @MainActor
    private func navigateBack(in app: XCUIApplication) {
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()
    }

    @MainActor
    private func selectNappyType(_ type: String, in app: XCUIApplication) {
        let nappyButton = app.buttons["quick-log-nappy-button"]
        XCTAssertTrue(nappyButton.waitForExistence(timeout: 5))
        nappyButton.tap()

        let typeButton = app.buttons[type]
        XCTAssertTrue(typeButton.waitForExistence(timeout: 5))
        typeButton.tap()
    }

    @MainActor
    private func tapDeleteContextAction(in app: XCUIApplication) {
        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 2) {
            deleteButton.tap()
            return
        }

        let deleteMenuItem = app.menuItems["Delete"]
        XCTAssertTrue(deleteMenuItem.waitForExistence(timeout: 5))
        deleteMenuItem.tap()
    }
}
