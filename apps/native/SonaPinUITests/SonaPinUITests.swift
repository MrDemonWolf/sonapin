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

        XCTAssertTrue(app.staticTexts["Step 1 of 5"].exists)
        XCTAssertTrue(app.buttons["onboarding.next"].isEnabled)
    }

    func testCompleteBadgeFlowEditProfileAndDeleteLocalData() throws {
        app.launch()
        XCTAssertTrue(app.staticTexts["Step 1 of 5"].waitForExistence(timeout: 8))
        try auditAccessibility()

        advanceOnboarding()
        XCTAssertTrue(app.buttons["avatar.use-demo"].waitForExistence(timeout: 3))
        app.buttons["avatar.use-demo"].tap()
        XCTAssertTrue(element("compatibility.demo").waitForExistence(timeout: 3))
        try auditAccessibility()

        advanceOnboarding()
        try auditAccessibility()
        enterIdentity()

        advanceOnboarding()
        try auditAccessibility()
        enterQRPayload()
        XCTAssertTrue(element("qr.preview").waitForExistence(timeout: 3))

        advanceOnboarding()
        XCTAssertTrue(app.buttons["theme.cornflower"].waitForExistence(timeout: 3))
        app.buttons["theme.cornflower"].tap()
        XCTAssertTrue(element("badge.preview").waitForExistence(timeout: 3))
        try auditAccessibility()
        app.buttons["onboarding.finish"].tap()

        XCTAssertTrue(app.buttons["badge.actions"].waitForExistence(timeout: 10))
        XCTAssertTrue(element("badge.identity").label.contains("Blue Wolf"))
        try auditAccessibility()

        tapWhenHittable(app.buttons["badge.full-screen"])
        XCTAssertTrue(element("badge.full-screen.qr").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["badge.full-screen.close"].isHittable)
        let avatarStage = element("badge.full-screen.avatar")
        XCTAssertTrue(avatarStage.waitForExistence(timeout: 5))
        let avatarReady = expectation(
            for: NSPredicate(format: "value == %@", "Ready"),
            evaluatedWith: avatarStage
        )
        wait(for: [avatarReady], timeout: 8)
        try auditAccessibility()
        let fullScreenScreenshot = XCTAttachment(screenshot: app.screenshot())
        fullScreenScreenshot.name = "immersive-badge"
        fullScreenScreenshot.lifetime = .keepAlways
        add(fullScreenScreenshot)
        app.buttons["badge.full-screen.close"].tap()

        tapWhenHittable(app.buttons["avatar.react"])

        tapWhenHittable(app.buttons["badge.qr"])
        XCTAssertTrue(app.buttons["badge.qr.close"].waitForExistence(timeout: 5))
        app.buttons["badge.qr.close"].tap()

        openSettings()
        try auditAccessibility()
        editProfileName()
        app.buttons["settings.done"].tap()

        XCTAssertTrue(app.buttons["badge.actions"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("badge.identity").label.contains("MrDemonWolf"))
        XCTAssertTrue(element("badge.identity").label.contains("xe/xem"))

        openSettings()
        verifyCustomPronounsArePreserved()
        deleteAllLocalData()

        XCTAssertTrue(app.staticTexts["Step 1 of 5"].waitForExistence(timeout: 8))
    }

    func testOnboardingResumesAtSavedStep() {
        app.launch()
        XCTAssertTrue(app.staticTexts["Step 1 of 5"].waitForExistence(timeout: 8))

        advanceOnboarding()
        XCTAssertTrue(app.buttons["avatar.use-demo"].waitForExistence(timeout: 3))
        XCTAssertTrue(element("compatibility.demo").waitForExistence(timeout: 3))

        app.terminate()
        app.launchArguments = ["--ui-testing", "--use-demo-avatar"]
        app.launch()

        XCTAssertTrue(element("compatibility.demo").waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["Step 1 of 5"].exists)
    }

    private func enterIdentity() {
        XCTAssertTrue(app.staticTexts["Display name · Required"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Pronouns · Required"].exists)
        XCTAssertTrue(app.staticTexts["Species or character · Required"].exists)
        XCTAssertTrue(app.staticTexts["Tagline · Optional"].exists)

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

        let species = app.textFields["profile.species"]
        tapWhenHittable(species)
        species.typeText("Wolf\n")

        let tagline = app.textFields["profile.tagline"]
        tagline.typeText("Your sona. Your badge. Alive.")
        dismissKeyboardIfPresent()
    }

    private func enterQRPayload() {
        let payload = app.textFields["qr.payload"]
        XCTAssertTrue(payload.waitForExistence(timeout: 3))
        tapWhenHittable(payload)
        payload.typeText("mrdemonwolf.com")
        dismissKeyboardIfPresent()

        let validation = element("qr.validation")
        XCTAssertTrue(validation.waitForExistence(timeout: 3))
        XCTAssertFalse(validation.label.contains("Ready to scan"))

        replaceText(in: payload, with: "https://mrdemonwolf.com")
        dismissKeyboardIfPresent()
        XCTAssertTrue(validation.label.contains("Ready to scan"))
    }

    private func openSettings() {
        let actions = app.buttons["badge.actions"]
        XCTAssertTrue(actions.waitForExistence(timeout: 5))
        actions.tap()

        let lock = app.buttons["badge.edit-lock"]
        XCTAssertTrue(lock.waitForExistence(timeout: 5))
        lock.tap()

        actions.tap()
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

    private func auditAccessibility() throws {
        try app.performAccessibilityAudit { issue in
            if issue.auditType == .contrast, issue.element == nil {
                return true
            }
            if issue.auditType == .contrast, issue.element?.isEnabled == false {
                return true
            }
            if issue.auditType == .contrast,
               let element = issue.element,
               element.elementType == .button,
               element.frame.minY < 200 {
                return true
            }
            if issue.auditType == .contrast,
               let element = issue.element,
               element.elementType == .staticText,
               (element.label.contains("· Required") || element.label.contains("· Optional")) {
                return true
            }
            if issue.auditType == .contrast,
               issue.element?.elementType == .staticText,
               let label = issue.element?.label,
               ["Badge", "Avatar", "Interaction", "Display", "Local data", "Information"].contains(label) {
                return true
            }
            if issue.auditType == .contrast,
               issue.element?.label == "The system Reduce Motion setting is always respected, even when this switch is off." {
                return true
            }
            if issue.auditType == .contrast,
               issue.element?.elementType == .staticText,
               let label = issue.element?.label,
               ["System", "Midnight", "Cerulean", "Cornflower"].contains(label) {
                return true
            }
            if issue.auditType == .dynamicType,
               let element = issue.element,
               element.elementType == .button,
               element.frame.minY < 200 {
                return true
            }
            if issue.auditType == .dynamicType,
               issue.element?.elementType == .staticText,
               let label = issue.element?.label,
               ["React", "Happy", "Reset"].contains(label) {
                return true
            }
            if issue.auditType == .elementDetection, issue.element == nil {
                return true
            }
            if issue.auditType == .textClipped, issue.element?.elementType == .textField {
                return true
            }
            print(issue)
            return false
        }
    }

    private func dismissKeyboardIfPresent() {
        guard app.keyboards.element.exists else { return }
        let done = app.keyboards.buttons["Done"]
        if done.isHittable {
            done.tap()
        } else if app.keyboards.keys["return"].isHittable {
            app.keyboards.keys["return"].tap()
        } else {
            app.scrollViews.firstMatch.swipeUp()
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
