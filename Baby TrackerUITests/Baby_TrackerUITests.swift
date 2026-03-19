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
    func testOwnerCanInviteActivateAndRemoveCaregiver() throws {
        let app = launchOwnerFlow()

        app.buttons["invite-caregiver-button"].tap()

        let inviteField = app.textFields["invite-caregiver-name-field"]
        XCTAssertTrue(inviteField.waitForExistence(timeout: 5))
        inviteField.tap()
        inviteField.typeText("Jamie Helper")
        app.buttons["invite-caregiver-save-button"].tap()

        XCTAssertTrue(app.staticTexts["Jamie Helper"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Mark Active"].waitForExistence(timeout: 5))
        app.buttons["Mark Active"].tap()

        XCTAssertTrue(app.staticTexts["Active Caregivers"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Remove"].waitForExistence(timeout: 5))
        app.buttons["Remove"].tap()

        XCTAssertTrue(app.staticTexts["Removed Caregivers"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOwnerCanArchiveAndRestoreOnlyChild() throws {
        let app = launchOwnerFlow()

        app.buttons["archive-child-button"].tap()
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
    func testActiveCaregiverDoesNotSeeOwnerActions() throws {
        let app = makeApp(scenario: "activeCaregiver")
        app.launch()

        XCTAssertTrue(app.staticTexts["child-profile-name"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["edit-child-button"].exists)
        XCTAssertFalse(app.buttons["invite-caregiver-button"].exists)
        XCTAssertFalse(app.buttons["archive-child-button"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            makeApp().launch()
        }
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

    private func makeApp(scenario: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["UI_TESTING"]

        if let scenario {
            app.launchEnvironment["UI_TEST_SCENARIO"] = scenario
        }

        return app
    }
}
