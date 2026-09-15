import XCTest

final class SonaPinUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-state", "--use-demo-avatar"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testFreshLaunchStartsOnWelcome() {
        app.launch()

        XCTAssertTrue(app.staticTexts["Step 1 of 9"].exists)
        XCTAssertTrue(app.buttons["onboarding.next"].isEnabled)
    }

    func testCompleteBadgeFlowEditProfileAndDeleteLocalData() {
        app.launch()
        XCTAssertTrue(app.staticTexts["Step 1 of 9"].waitForExistence(timeout: 8))

        advanceOnboarding()
        XCTAssertTrue(app.buttons["avatar.use-demo"].waitForExistence(timeout: 3))
        app.buttons["avatar.use-demo"].tap()

        advanceOnboarding()
        XCTAssertTrue(element("compatibility.demo").waitForExistence(timeout: 3))

        advanceOnboarding()
        enterIdentity()

        advanceOnboarding()
        enterQRPayload()

        advanceOnboarding()
        XCTAssertTrue(element("qr.preview").waitForExistence(timeout: 3))

        advanceOnboarding()
        XCTAssertTrue(app.buttons["theme.cornflower"].waitForExistence(timeout: 3))
        app.buttons["theme.cornflower"].tap()

        advanceOnboarding()
        XCTAssertTrue(element("badge.preview").waitForExistence(timeout: 3))

        advanceOnboarding()
        XCTAssertTrue(element("onboarding.complete").waitForExistence(timeout: 3))
        app.buttons["onboarding.finish"].tap()

        XCTAssertTrue(app.buttons["badge.edit-lock"].waitForExistence(timeout: 10))
        XCTAssertTrue(element("badge.identity").label.contains("Blue Wolf"))

        tapWhenHittable(app.buttons["avatar.react"])

        tapWhenHittable(app.buttons["badge.qr"])
        XCTAssertTrue(app.buttons["badge.qr.close"].waitForExistence(timeout: 5))
        app.buttons["badge.qr.close"].tap()

        openSettings()
        editProfileName()
        app.buttons["settings.done"].tap()

        XCTAssertTrue(app.buttons["badge.edit-lock"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("badge.identity").label.contains("MrDemonWolf"))

        openSettings()
        deleteAllLocalData()

        XCTAssertTrue(app.staticTexts["Step 1 of 9"].waitForExistence(timeout: 8))
    }

    func testOnboardingResumesAtSavedStep() {
        app.launch()
        XCTAssertTrue(app.staticTexts["Step 1 of 9"].waitForExistence(timeout: 8))

        advanceOnboarding()
        XCTAssertTrue(app.buttons["avatar.use-demo"].waitForExistence(timeout: 3))
        advanceOnboarding()
        XCTAssertTrue(element("compatibility.demo").waitForExistence(timeout: 3))

        app.terminate()
        app.launchArguments = ["--ui-testing", "--use-demo-avatar"]
        app.launch()

        XCTAssertTrue(element("compatibility.demo").waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["Step 1 of 9"].exists)
    }

    private func enterIdentity() {
        let displayName = app.textFields["profile.display-name"]
        XCTAssertTrue(displayName.waitForExistence(timeout: 3))
        displayName.tap()
        displayName.typeText("Blue Wolf")

        let pronouns = app.textFields["profile.pronouns"]
        pronouns.tap()
        pronouns.typeText("he/him")

        let species = app.textFields["profile.species"]
        species.tap()
        species.typeText("Wolf")

        let tagline = app.textFields["profile.tagline"]
        tagline.tap()
        tagline.typeText("Your sona. Your badge. Alive.")
        dismissKeyboardIfPresent()
    }

    private func enterQRPayload() {
        let payload = app.textFields["qr.payload"]
        XCTAssertTrue(payload.waitForExistence(timeout: 3))
        payload.tap()
        payload.typeText("https://mrdemonwolf.com")
        dismissKeyboardIfPresent()
    }

    private func openSettings() {
        let lock = app.buttons["badge.edit-lock"]
        XCTAssertTrue(lock.waitForExistence(timeout: 5))
        lock.tap()

        let settings = app.buttons["badge.settings"]
        XCTAssertTrue(settings.isEnabled)
        settings.tap()
        XCTAssertTrue(app.buttons["settings.done"].waitForExistence(timeout: 5))
    }

    private func editProfileName() {
        let profile = app.buttons["settings.profile"]
        XCTAssertTrue(profile.waitForExistence(timeout: 3))
        profile.tap()

        let displayName = app.textFields["profile.display-name"]
        XCTAssertTrue(displayName.waitForExistence(timeout: 3))
        replaceText(in: displayName, with: "MrDemonWolf")
        dismissKeyboardIfPresent()
        app.buttons["profile.save"].tap()

        XCTAssertTrue(app.buttons["settings.done"].waitForExistence(timeout: 3))
    }

    private func deleteAllLocalData() {
        let delete = app.buttons["settings.delete-all"]
        reveal(delete)
        delete.tap()

        let confirm = app.buttons["settings.delete-all.confirm"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        confirm.tap()
    }

    private func advanceOnboarding() {
        dismissKeyboardIfPresent()
        let next = app.buttons["onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 4))
        XCTAssertTrue(next.isEnabled)
        next.tap()
    }

    private func dismissKeyboardIfPresent() {
        guard app.keyboards.element.exists else { return }
        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else {
            app.tap()
        }
    }

    private func replaceText(in field: XCUIElement, with newValue: String) {
        field.tap()
        let oldValue = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: oldValue.count))
        field.typeText(newValue)
    }

    private func tapWhenHittable(_ element: XCUIElement) {
        reveal(element)
        XCTAssertTrue(element.isHittable)
        element.tap()
    }

    private func reveal(_ element: XCUIElement) {
        for _ in 0 ..< 6 where !element.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(element.waitForExistence(timeout: 3))
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
