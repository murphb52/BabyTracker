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
        XCTAssertTrue(profileName.waitForExistence(timeout: 5))
        XCTAssertEqual(profileName.label, "Poppy")
    }

    @MainActor
    func testOwnerSeesStage2SharingUIWithoutActivationControls() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        XCTAssertTrue(app.staticTexts["child-profile-name"].waitForExistence(timeout: 5))
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

        XCTAssertTrue(app.staticTexts["child-profile-name"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOwnerCanQuickLogBreastFeed() throws {
        let app = makeApp(scenario: "ownerPreview")
        app.launch()

        XCTAssertTrue(app.buttons["quick-log-breast-feed-button"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["feeding-empty-state"].exists)

        app.buttons["quick-log-breast-feed-button"].tap()

        let saveButton = app.buttons["save-breast-feed-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        let latestFeedValue = app.staticTexts["feeding-latest-feed-value"]
        XCTAssertTrue(latestFeedValue.waitForExistence(timeout: 5))
        XCTAssertEqual(latestFeedValue.label, "Breast Feed")
        XCTAssertEqual(app.staticTexts["feeding-count-value"].label, "1")
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

        let latestFeedValue = app.staticTexts["feeding-latest-feed-value"]
        XCTAssertTrue(latestFeedValue.waitForExistence(timeout: 5))
        XCTAssertEqual(latestFeedValue.label, "Bottle Feed")
        XCTAssertEqual(app.staticTexts["feeding-count-value"].label, "1")
    }

    @MainActor
    func testActiveCaregiverDoesNotSeeOwnerActions() throws {
        let app = makeApp(scenario: "activeCaregiver")
        app.launch()

        XCTAssertTrue(app.staticTexts["child-profile-name"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["quick-log-bottle-feed-button"].exists)
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

        let latestFeedValue = app.staticTexts["feeding-latest-feed-value"]
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

        XCTAssertTrue(app.staticTexts["child-profile-name"].waitForExistence(timeout: 5))

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

    private func makeApp(scenario: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["UI_TESTING"]

        if let scenario {
            app.launchEnvironment["UI_TEST_SCENARIO"] = scenario
        }

        return app
    }
}
