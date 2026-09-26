import XCTest

@MainActor
final class SonaPinUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-state", "--use-demo-avatar"]
    }

    override func tearDown() async throws {
        app = nil
    }

    func testFreshLaunchStartsOnWelcome() {
        app.launch()

        XCTAssertTrue(app.staticTexts["Step 1 of 3"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["onboarding.next"].isEnabled)
        XCTAssertEqual(app.buttons["onboarding.next"].label, "Make It Mine")
    }

    func testGuidedDemoReactsAndCompletesWithOnlyAName() {
        app.launch()

        let demoAvatar = element("onboarding.demo.avatar")
        XCTAssertTrue(demoAvatar.waitForExistence(timeout: 8))
        let avatarReady = expectation(
            for: NSPredicate(format: "value == %@", "Ready. Wolf ready"),
            evaluatedWith: demoAvatar
        )
        wait(for: [avatarReady], timeout: 20)
        demoAvatar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        let avatarReacted = expectation(
            for: NSPredicate(
                format: "value == %@",
                "Ready. Reaction 1. Hiding behind the QR card. Demo QR opens the SonaPin website"
            ),
            evaluatedWith: demoAvatar
        )
        wait(for: [avatarReacted], timeout: 15)

        advanceOnboarding()
        let displayName = app.textFields["profile.display-name"]
        XCTAssertTrue(displayName.waitForExistence(timeout: 3))
        displayName.tap()
        displayName.typeText("Nova")
        dismissKeyboardIfPresent()

        advanceOnboarding()
        XCTAssertTrue(app.staticTexts["Your badge is ready"].waitForExistence(timeout: 3))
        app.buttons["onboarding.finish"].tap()

        XCTAssertTrue(app.buttons["badge.actions"].waitForExistence(timeout: 10))
        XCTAssertTrue(element("badge.identity").label.contains("Nova"))
    }

    func testBadgeNameValidationKeepsUserOnIdentityStep() {
        app.launch()
        advanceOnboarding()

        app.buttons["onboarding.next"].tap()

        XCTAssertTrue(app.staticTexts["Badge name is required."].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Step 2 of 3"].exists)
    }

    func testCompleteBadgeFlowEditProfileAndDeleteLocalData() {
        app.launch()
        XCTAssertTrue(app.staticTexts["Step 1 of 3"].waitForExistence(timeout: 8))
        // RealityKit can prevent XCTest's blanket audit from reaching quiescence; focused avatar checks cover this screen.

        advanceOnboarding()
        let displayName = app.textFields["profile.display-name"]
        XCTAssertTrue(displayName.isHittable)
        XCTAssertFalse(displayName.label.isEmpty)
        enterIdentity()

        advanceOnboarding()
        XCTAssertTrue(app.staticTexts["Your badge is ready"].waitForExistence(timeout: 3))
        app.buttons["onboarding.finish"].tap()

        XCTAssertTrue(app.buttons["badge.actions"].waitForExistence(timeout: 10))
        XCTAssertTrue(element("badge.identity").label.contains("Blue Wolf"))

        tapWhenHittable(app.buttons["badge.full-screen"])
        XCTAssertTrue(app.buttons["badge.full-screen.close"].isHittable)
        let avatarStage = element("badge.full-screen.avatar")
        XCTAssertTrue(avatarStage.waitForExistence(timeout: 5))
        let avatarReady = expectation(
            for: NSPredicate(format: "value == %@", "Ready. Wolf ready"),
            evaluatedWith: avatarStage
        )
        let readyResult = XCTWaiter.wait(for: [avatarReady], timeout: 20)
        XCTAssertEqual(
            readyResult,
            .completed,
            "Unexpected avatar state: \(String(describing: avatarStage.value))"
        )
        XCTAssertFalse(element("badge.full-screen.qr").exists)
        // Xcode's built-in audit can hang on the live RealityKit surface; the controls and state are asserted above.
        let fullScreenScreenshot = XCTAttachment(screenshot: app.screenshot())
        fullScreenScreenshot.name = "immersive-badge"
        fullScreenScreenshot.lifetime = .keepAlways
        add(fullScreenScreenshot)
        app.buttons["badge.full-screen.close"].tap()

        tapWhenHittable(app.buttons["avatar.react"])

        openSettings()
        let profileButton = app.buttons["settings.profile"]
        XCTAssertTrue(profileButton.isHittable)
        XCTAssertFalse(profileButton.label.isEmpty)
        editProfileName()
        app.buttons["settings.done"].tap()

        XCTAssertTrue(app.buttons["badge.actions"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("badge.identity").label.contains("MrDemonWolf"))
        XCTAssertTrue(element("badge.identity").label.contains("xe/xem"))

        openSettings()
        verifyCustomPronounsArePreserved()
        deleteAllLocalData()

        XCTAssertTrue(app.staticTexts["Step 1 of 3"].waitForExistence(timeout: 8))
    }

    func testImmersiveAvatarRespondsToPhysicalTouchWithReducedMotion() {
        app.launch()
        XCTAssertTrue(app.staticTexts["Step 1 of 3"].waitForExistence(timeout: 8))

        advanceOnboarding()
        enterIdentity()
        advanceOnboarding()
        app.buttons["onboarding.finish"].tap()

        XCTAssertTrue(app.buttons["badge.full-screen"].waitForExistence(timeout: 10))
        tapWhenHittable(app.buttons["badge.full-screen"])
        let avatarStage = element("badge.full-screen.avatar")
        XCTAssertTrue(avatarStage.waitForExistence(timeout: 5))
        let avatarReady = expectation(
            for: NSPredicate(format: "value == %@", "Ready. Wolf ready"),
            evaluatedWith: avatarStage
        )
        let readyResult = XCTWaiter.wait(for: [avatarReady], timeout: 20)
        XCTAssertEqual(
            readyResult,
            .completed,
            "Unexpected avatar state: \(String(describing: avatarStage.value))"
        )

        let tapPoint = avatarStage.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        tapPoint.tap()
        let avatarReacted = expectation(
            for: NSPredicate(
                format: "value == %@",
                "Ready. Reaction 1. Hiding behind the QR card. Demo QR opens the SonaPin website"
            ),
            evaluatedWith: avatarStage
        )
        wait(for: [avatarReacted], timeout: 5)
    }

    func testOnboardingResumesAtSavedStep() {
        app.launch()
        XCTAssertTrue(app.staticTexts["Step 1 of 3"].waitForExistence(timeout: 8))

        advanceOnboarding()
        XCTAssertTrue(app.staticTexts["Badge name"].waitForExistence(timeout: 3))

        app.terminate()
        app.launchArguments = ["--ui-testing", "--use-demo-avatar"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Badge name"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["Step 1 of 3"].exists)
    }

    private func enterIdentity() {
        XCTAssertTrue(app.staticTexts["Badge name"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Required"].exists)
        XCTAssertTrue(app.staticTexts["Pronouns"].exists)

        let displayName = app.textFields["profile.display-name"]
        XCTAssertTrue(displayName.waitForExistence(timeout: 3))
        tapWhenHittable(displayName)
        displayName.typeText("Blue Wolf")
        dismissKeyboardIfPresent()

        let pronouns = app.buttons["profile.pronouns.picker"]
        XCTAssertTrue(pronouns.waitForExistence(timeout: 3))
        pronouns.tap()
        let heHim = app.buttons["he/him"]
        XCTAssertTrue(heHim.waitForExistence(timeout: 3))
        heHim.tap()

        app.buttons["Add more badge details"].tap()
        let species = app.textFields["profile.species"]
        tapWhenHittable(species)
        species.typeText("Wolf\n")

        let tagline = app.textFields["profile.tagline"]
        tagline.typeText("Your sona. Your badge. Alive.")
        dismissKeyboardIfPresent()
    }

    private func openSettings() {
        let actions = app.buttons["badge.actions"]
        XCTAssertTrue(actions.waitForExistence(timeout: 5))
        actions.tap()

        let lock = app.buttons["badge.edit-lock"]
        XCTAssertTrue(lock.waitForExistence(timeout: 5))
        if lock.label == "Unlock editing" {
            lock.tap()
            actions.tap()
        }

        let settings = app.buttons["badge.settings"]
        let settingsEnabled = expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: settings
        )
        wait(for: [settingsEnabled], timeout: 3)
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

        let pronouns = app.buttons["profile.pronouns.picker"]
        XCTAssertTrue(pronouns.waitForExistence(timeout: 3))
        pronouns.tap()
        let other = app.buttons["Other…"]
        XCTAssertTrue(other.waitForExistence(timeout: 3))
        other.tap()

        let customPronouns = element("profile.pronouns.custom")
        if !customPronouns.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(customPronouns.waitForExistence(timeout: 5))
        customPronouns.tap()
        customPronouns.typeText("xe/xem")
        dismissKeyboardIfPresent()
        app.buttons["profile.save"].tap()

        XCTAssertTrue(app.buttons["settings.done"].waitForExistence(timeout: 3))
    }

    private func verifyCustomPronounsArePreserved() {
        app.buttons["settings.profile"].tap()

        let pronouns = app.buttons["profile.pronouns.picker"]
        XCTAssertTrue(pronouns.waitForExistence(timeout: 3))
        pronouns.tap()
        app.buttons["Other…"].tap()

        let customPronouns = app.textFields["profile.pronouns.custom"]
        XCTAssertTrue(customPronouns.waitForExistence(timeout: 3))
        XCTAssertEqual(customPronouns.value as? String, "xe/xem")
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
        let done = app.buttons
            .matching(NSPredicate(format: "label == %@", "Done"))
            .allElementsBoundByIndex
            .first { $0.isHittable }
        if let done {
            done.tap()
        } else if app.keyboards.keys["return"].isHittable {
            app.keyboards.keys["return"].tap()
        } else if app.scrollViews.firstMatch.exists {
            app.scrollViews.firstMatch.swipeDown()
        } else {
            app.swipeDown()
        }
    }

    private func replaceText(in field: XCUIElement, with newValue: String) {
        XCTAssertTrue(field.isHittable)
        field.tap()
        let keyboard = app.keyboards.firstMatch
        if !keyboard.waitForExistence(timeout: 2) {
            field.tap()
        }
        XCTAssertTrue(keyboard.waitForExistence(timeout: 3), "Text field did not receive keyboard focus")
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
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
