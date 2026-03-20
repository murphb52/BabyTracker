import XCTest

final class Baby_TrackerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFirstLaunchFlowsIntoChildProfile() throws {
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

        let profileName = app.staticTexts["child-profile-name"]
        scrollToElement(profileName, in: app)
        XCTAssertTrue(profileName.exists)
        XCTAssertEqual(profileName.label, "Poppy")
    }

    @MainActor
    func testOwnerSeesStage2SharingUIWithoutActivationControls() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        let profileName = app.staticTexts["child-profile-name"]
        scrollToElement(profileName, in: app)
        XCTAssertTrue(profileName.exists)
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
        let app = launchOwnerFlow()

        let archiveButton = app.buttons["archive-child-button"]
        scrollToElement(archiveButton, in: app)
        XCTAssertTrue(archiveButton.exists)

        archiveButton.tap()
        app.sheets.buttons["Archive Child"].tap()

        XCTAssertTrue(app.buttons["create-child-button"].waitForExistence(timeout: 5))

        let restoreButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Restore ")
        ).firstMatch
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 5))
        restoreButton.tap()

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

        XCTAssertTrue(app.buttons["quick-log-nappy-button"].waitForExistence(timeout: 5))

        app.buttons["quick-log-nappy-button"].tap()
        app.sheets.buttons["Poo"].tap()

        let saveButton = app.buttons["save-nappy-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        let latestEventValue = app.staticTexts["current-status-last-event-value"]
        XCTAssertTrue(latestEventValue.waitForExistence(timeout: 5))
        XCTAssertEqual(latestEventValue.label, "Nappy")
        XCTAssertTrue(app.staticTexts["current-status-last-nappy-value"].waitForExistence(timeout: 5))

        let recentNappyButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "recent-nappy-")
        ).firstMatch
        scrollToElement(recentNappyButton, in: app, maxSwipes: 10)
        XCTAssertTrue(recentNappyButton.waitForExistence(timeout: 5))
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

        let recentSleepButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "recent-sleep-")
        ).firstMatch
        scrollToElement(recentSleepButton, in: app, maxSwipes: 10)
        XCTAssertTrue(recentSleepButton.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["quick-log-sleep-button"].label, "Start Sleep")
    }

    @MainActor
    func testSleepEndSheetDisablesSaveWhenEndPrecedesStart() throws {
        let app = makeApp(scenario: "futureActiveSleepPreview")
        app.launch()

        let sleepButton = app.buttons["quick-log-sleep-button"]
        XCTAssertTrue(sleepButton.waitForExistence(timeout: 5))
        XCTAssertEqual(sleepButton.label, "End Sleep")

        sleepButton.tap()

        let saveButton = app.buttons["save-sleep-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        XCTAssertFalse(saveButton.isEnabled)
        XCTAssertTrue(app.staticTexts["End time must be later than the start time."].exists)
    }

    @MainActor
    func testOwnerCanOpenEditSleepFlowFromRecentSleep() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        createCompletedSleep(in: app)

        let recentSleepButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "recent-sleep-")
        ).firstMatch
        scrollToElement(recentSleepButton, in: app, maxSwipes: 10)
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

        let recentSleepButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "recent-sleep-")
        ).firstMatch
        scrollToElement(recentSleepButton, in: app, maxSwipes: 10)
        XCTAssertTrue(recentSleepButton.waitForExistence(timeout: 5))
        recentSleepButton.swipeLeft()
        app.buttons["Delete"].tap()

        let confirmDeleteButton = app.sheets.buttons["Delete Sleep"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 5))
        confirmDeleteButton.tap()

        let undoButton = app.buttons["undo-delete-button"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["recent-sleep-empty-state"].exists)

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

        app.buttons["quick-log-nappy-button"].tap()
        app.sheets.buttons["Dry"].tap()

        XCTAssertTrue(app.buttons["save-nappy-button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["nappy-poo-color-picker"].exists)
        app.buttons["Cancel"].tap()

        app.buttons["quick-log-nappy-button"].tap()
        app.sheets.buttons["Mixed"].tap()

        XCTAssertTrue(app.buttons["nappy-poo-color-picker"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testActiveCaregiverDoesNotSeeOwnerActions() throws {
        let app = makeApp(scenario: "activeCaregiver")
        app.launch()

        XCTAssertTrue(app.buttons["quick-log-bottle-feed-button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["edit-child-button"].exists)
        XCTAssertFalse(app.buttons["share-child-button"].exists)
        XCTAssertFalse(app.buttons["archive-child-button"].exists)
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
    func testOwnerCanEditBreastFeedFromRecentFeeds() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        app.buttons["quick-log-breast-feed-button"].tap()
        XCTAssertTrue(app.buttons["save-breast-feed-button"].waitForExistence(timeout: 5))
        app.buttons["save-breast-feed-button"].tap()

        let recentFeedButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "recent-feed-")
        ).firstMatch
        scrollToElement(recentFeedButton, in: app, maxSwipes: 10)
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

        let recentFeedButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "recent-feed-")
        ).firstMatch
        scrollToElement(recentFeedButton, in: app, maxSwipes: 10)
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
    func testDeleteRequiresConfirmationAndUndoRestoresFeed() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        app.buttons["quick-log-bottle-feed-button"].tap()
        XCTAssertTrue(app.buttons["save-bottle-feed-button"].waitForExistence(timeout: 5))
        app.buttons["save-bottle-feed-button"].tap()

        let recentFeedButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "recent-feed-")
        ).firstMatch
        scrollToElement(recentFeedButton, in: app, maxSwipes: 10)
        XCTAssertTrue(recentFeedButton.waitForExistence(timeout: 5))
        recentFeedButton.swipeLeft()
        app.buttons["Delete"].tap()

        let confirmDeleteButton = app.sheets.buttons["Delete Feed"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 5))
        confirmDeleteButton.tap()

        let undoButton = app.buttons["undo-delete-button"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["recent-feeds-empty-state"].exists)

        undoButton.tap()

        XCTAssertTrue(recentFeedButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testDeleteRequiresConfirmationAndUndoRestoresNappy() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        app.buttons["quick-log-nappy-button"].tap()
        app.sheets.buttons["Mixed"].tap()
        XCTAssertTrue(app.buttons["save-nappy-button"].waitForExistence(timeout: 5))
        app.buttons["save-nappy-button"].tap()

        let recentNappyButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "recent-nappy-")
        ).firstMatch
        scrollToElement(recentNappyButton, in: app, maxSwipes: 10)
        XCTAssertTrue(recentNappyButton.waitForExistence(timeout: 5))
        recentNappyButton.swipeLeft()
        app.buttons["Delete"].tap()

        let confirmDeleteButton = app.sheets.buttons["Delete Nappy"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 5))
        confirmDeleteButton.tap()

        let undoButton = app.buttons["undo-delete-button"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["recent-nappies-empty-state"].exists)

        undoButton.tap()

        XCTAssertTrue(recentNappyButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testRecentFeedsEmptyStateAppearsBeforeLogging() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        let emptyState = app.staticTexts["recent-feeds-empty-state"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5))
        XCTAssertEqual(
            emptyState.label,
            "No feeds logged yet. Use Quick Log above to add the first feed."
        )
    }

    @MainActor
    func testMixedEventsScenarioShowsLatestEventButKeepsFeedHistoryFeedOnly() throws {
        let app = makeApp(scenario: "mixedEventsPreview")
        app.launch()

        XCTAssertTrue(app.staticTexts["current-status-last-event-value"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["current-status-last-event-value"].label, "Sleep")
        XCTAssertEqual(app.staticTexts["current-status-last-event-detail"].label, "30 min")
        XCTAssertEqual(app.staticTexts["current-status-feeds-today-value"].label, "1")
        XCTAssertFalse(app.staticTexts["current-status-since-last-feed-value"].label.isEmpty)

        let recentFeedButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "recent-feed-")
        ).firstMatch
        scrollToElement(recentFeedButton, in: app, maxSwipes: 10)
        XCTAssertTrue(recentFeedButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bottle Feed"].exists)
        XCTAssertFalse(app.staticTexts["Sleep"].exists && recentFeedButton.label == "Sleep")
    }

    @MainActor
    func testTimelineScreenShowsEmptyStateForOwnerPreview() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        let timelineButton = app.buttons["open-timeline-button"]
        scrollToElement(timelineButton, in: app, maxSwipes: 10)
        XCTAssertTrue(timelineButton.waitForExistence(timeout: 5))
        timelineButton.tap()

        XCTAssertTrue(app.staticTexts["timeline-empty-state"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTimelineDayNavigationCanReturnToToday() throws {
        let app = makeApp(scenario: "mixedEventsPreview")
        app.launch()

        let timelineButton = app.buttons["open-timeline-button"]
        scrollToElement(timelineButton, in: app, maxSwipes: 10)
        timelineButton.tap()

        let todayTitle = app.staticTexts["timeline-day-title"]
        XCTAssertTrue(todayTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(todayTitle.label, "Today")

        app.buttons["timeline-previous-day-button"].tap()

        let jumpToTodayButton = app.buttons["timeline-jump-to-today-button"]
        XCTAssertTrue(jumpToTodayButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["timeline-empty-state"].waitForExistence(timeout: 5))

        jumpToTodayButton.tap()

        XCTAssertEqual(app.staticTexts["timeline-day-title"].label, "Today")
        XCTAssertTrue(
            app.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH %@", "timeline-event-")
            ).firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testTimelineBottleFeedRowOpensEditFlow() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        app.buttons["quick-log-bottle-feed-button"].tap()
        XCTAssertTrue(app.buttons["save-bottle-feed-button"].waitForExistence(timeout: 5))
        app.buttons["save-bottle-feed-button"].tap()

        let timelineButton = app.buttons["open-timeline-button"]
        scrollToElement(timelineButton, in: app, maxSwipes: 10)
        timelineButton.tap()

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

        let timelineButton = app.buttons["open-timeline-button"]
        scrollToElement(timelineButton, in: app, maxSwipes: 10)
        timelineButton.tap()

        let activeSleepEvent = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "timeline-event-")
        ).firstMatch
        XCTAssertTrue(activeSleepEvent.waitForExistence(timeout: 5))
        activeSleepEvent.tap()

        XCTAssertTrue(app.buttons["save-sleep-button"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTimelineDeleteShowsUndoAndRemovesRow() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        app.buttons["quick-log-bottle-feed-button"].tap()
        XCTAssertTrue(app.buttons["save-bottle-feed-button"].waitForExistence(timeout: 5))
        app.buttons["save-bottle-feed-button"].tap()

        let timelineButton = app.buttons["open-timeline-button"]
        scrollToElement(timelineButton, in: app, maxSwipes: 10)
        timelineButton.tap()

        let timelineEvent = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "timeline-event-")
        ).firstMatch
        XCTAssertTrue(timelineEvent.waitForExistence(timeout: 5))
        timelineEvent.swipeLeft()
        app.buttons["Delete"].tap()

        let confirmDeleteButton = app.sheets.buttons["Delete Feed"]
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

        let profileName = app.staticTexts["child-profile-name"]
        scrollToElement(profileName, in: app)
        XCTAssertTrue(profileName.exists)

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
}
