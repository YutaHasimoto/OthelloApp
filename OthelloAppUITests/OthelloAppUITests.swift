//
//  OthelloAppUITests.swift
//  OthelloAppUITests
//
//  Created by 橋本雄太 on 2024/08/31.
//

import XCTest

final class OthelloAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testOpeningMoveCanBePlayed() throws {
        let app = XCUIApplication()
        app.launch()

        let twoPlayerButton = app.buttons["startTwoPlayerButton"]
        XCTAssertTrue(twoPlayerButton.waitForExistence(timeout: 5))

        let buttonIsHittable = NSPredicate(format: "isHittable == true")
        expectation(for: buttonIsHittable, evaluatedWith: twoPlayerButton)
        waitForExpectations(timeout: 2)

        twoPlayerButton.tap()

        let openingMove = app.buttons["boardCell-2-3"]
        XCTAssertTrue(openingMove.waitForExistence(timeout: 3))

        openingMove.tap()

        XCTAssertTrue(app.buttons["boardCell-2-3"].waitForExistence(timeout: 3))
    }

    func testTwoPlayerBoardDoesNotScroll() throws {
        try assertGameBoardDoesNotScroll(startButtonIdentifier: "startTwoPlayerButton")
    }

    func testCPUBoardDoesNotScroll() throws {
        try assertGameBoardDoesNotScroll(startButtonIdentifier: "startCPUButton-easy")
    }

    func testCPUSecondPlayerSelectionStartsWithBlackCPUMove() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()

        let secondPlayerButton = app.buttons["selectCPUSecondButton"]
        XCTAssertTrue(secondPlayerButton.waitForExistence(timeout: 5))
        secondPlayerButton.tap()
        XCTAssertTrue(secondPlayerButton.isSelected)

        app.buttons["startCPUButton-easy"].tap()
        XCTAssertTrue(app.buttons["boardCell-0-0"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["白"].exists)

        let openingCells = ["boardCell-2-3", "boardCell-3-2", "boardCell-4-5", "boardCell-5-4"]
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline && !openingCells.contains(where: { app.buttons[$0].label.contains("黒") }) {
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTAssertTrue(openingCells.contains(where: { app.buttons[$0].label.contains("黒") }))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "置ける場所")).count > 0)
    }

    func testCompactPortraitAndWideLandscapeKeepGameControlsVisible() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        assertWindowOrientation(.portrait, in: app)

        let twoPlayerButton = app.buttons["startTwoPlayerButton"]
        let firstTurnButton = app.buttons["selectCPUFirstButton"]
        let secondTurnButton = app.buttons["selectCPUSecondButton"]
        let easyCPUButton = app.buttons["startCPUButton-easy"]
        XCTAssertTrue(waitUntilHittable(twoPlayerButton, timeout: 5), "The menu did not become interactive")
        for button in [twoPlayerButton, firstTurnButton, secondTurnButton, easyCPUButton] {
            XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing menu button: \(button.identifier)")
            if !button.isHittable { app.swipeUp() }
            XCTAssertTrue(waitUntilHittable(button, timeout: 3), "Menu button is not reachable: \(button.identifier)")
            assertFitsInWindow(button, in: app)
        }
        keepScreenshot(named: "adaptive-menu-portrait")

        easyCPUButton.tap()
        keepScreenshot(named: "adaptive-game-initial-portrait")
        assertBoardAndControlsFit(in: app)

        let openingMove = app.buttons["boardCell-2-3"]
        XCTAssertTrue(openingMove.waitForExistence(timeout: 5))
        let beforeMove = openingMove.label
        XCTAssertTrue(beforeMove.contains("available move"), "The opening cell is not a legal move")
        openingMove.tap()
        let blackDiscAppears = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", "Black"),
            object: openingMove
        )
        XCTAssertEqual(XCTWaiter.wait(for: [blackDiscAppears], timeout: 5), .completed)
        let playedDisc = openingMove.label
        XCTAssertNotEqual(playedDisc, beforeMove, "The move did not change the board cell")
        waitForCPUControlsToEnable(in: app)
        assertBoardAndControlsFit(in: app)
        keepScreenshot(named: "adaptive-game-portrait")

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.buttons["boardCell-0-0"].waitForExistence(timeout: 5))
        assertWindowOrientation(.landscape, in: app)
        waitForCPUControlsToEnable(in: app)
        assertBoardAndControlsFit(in: app)
        XCTAssertEqual(openingMove.label, playedDisc, "Rotating the screen changed the played disc")
        keepScreenshot(named: "adaptive-game-landscape")
    }

    func testResultActionsFitInPortraitAndLandscape() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        assertWindowOrientation(.portrait, in: app)

        let twoPlayerButton = app.buttons["startTwoPlayerButton"]
        XCTAssertTrue(twoPlayerButton.waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntilHittable(twoPlayerButton, timeout: 5))
        twoPlayerButton.tap()

        let result = app.otherElements["resultScreen"]
        let legalMove = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "boardCell-", "available move")
        )
        for move in 0..<60 {
            if result.exists { break }
            if legalMove.count == 0 {
                XCTAssertTrue(result.waitForExistence(timeout: 3), "No legal move at turn \(move), but the result is absent")
                break
            }
            legalMove.firstMatch.tap()
        }
        XCTAssertTrue(result.waitForExistence(timeout: 5), "The two-player game did not reach its result")

        assertResultActionsFit(in: app)
        keepScreenshot(named: "adaptive-result-portrait")

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        assertWindowOrientation(.landscape, in: app)
        assertResultActionsFit(in: app)
        keepScreenshot(named: "adaptive-result-landscape")
    }

    private func assertBoardAndControlsFit(in app: XCUIApplication) {
        let corners = ["boardCell-0-0", "boardCell-0-7", "boardCell-7-0", "boardCell-7-7"]
        for identifier in corners {
            let cell = app.buttons[identifier]
            XCTAssertTrue(cell.waitForExistence(timeout: 5), "Missing board corner: \(identifier)")
            XCTAssertTrue(waitUntilHittable(cell, timeout: 3), "Board corner cannot be tapped: \(identifier)")
            assertFitsInWindow(cell, in: app)
            XCTAssertGreaterThanOrEqual(cell.frame.width + 0.01, 24, "Board cells are too narrow to tap")
            XCTAssertGreaterThanOrEqual(cell.frame.height + 0.01, 24, "Board cells are too short to tap")
        }

        for title in ["Menu", "Restart"] {
            let buttons = app.buttons.matching(NSPredicate(format: "label == %@", title))
            XCTAssertEqual(buttons.count, 2, "Expected a \(title) control for each player")
            for index in 0..<buttons.count {
                let button = buttons.element(boundBy: index)
                XCTAssertTrue(
                    waitUntilHittable(button, timeout: 3),
                    "\(title) control \(index) cannot be tapped: \(controlDiagnostics(buttons, in: app))"
                )
                assertFitsInWindow(button, in: app)
                XCTAssertGreaterThanOrEqual(button.frame.width + 0.01, 44, "\(title) control is too narrow")
                XCTAssertGreaterThanOrEqual(button.frame.height + 0.01, 44, "\(title) control is too short")
            }
        }
    }

    private func controlDiagnostics(_ buttons: XCUIElementQuery, in app: XCUIApplication) -> String {
        let controls = (0..<buttons.count).map { index in
            let button = buttons.element(boundBy: index)
            return "[\(index)] frame=\(button.frame), enabled=\(button.isEnabled), hittable=\(button.isHittable)"
        }
        return "\(controls.joined(separator: "; ")); window=\(app.windows.firstMatch.frame)"
    }

    private func waitForCPUControlsToEnable(in app: XCUIApplication) {
        let legalMoves = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "boardCell-", "available move")
        )
        let deadline = Date().addingTimeInterval(8)
        while Date() < deadline && legalMoves.count == 0 {
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTAssertGreaterThan(legalMoves.count, 0, "The CPU has not returned control to the player")

        let restartButtons = app.buttons.matching(NSPredicate(format: "label == %@", "Restart"))
        XCTAssertEqual(restartButtons.count, 2)
        for index in 0..<restartButtons.count {
            let button = restartButtons.element(boundBy: index)
            let enabled = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "isEnabled == true"),
                object: button
            )
            XCTAssertEqual(
                XCTWaiter.wait(for: [enabled], timeout: 8),
                .completed,
                "CPU turn did not finish before checking Restart control \(index)"
            )
        }
    }

    private func assertResultActionsFit(in app: XCUIApplication) {
        let result = app.otherElements["resultScreen"]
        XCTAssertTrue(result.exists)

        for identifier in ["dismissResultButton", "playAgainButton", "resultMenuButton"] {
            let button = app.buttons[identifier]
            XCTAssertTrue(button.exists, "Missing result action: \(identifier)")
            if !button.isHittable {
                result.swipeUp()
            }
            XCTAssertTrue(waitUntilHittable(button, timeout: 3), "Result action cannot be tapped: \(identifier)")
            assertFitsInWindow(button, in: app)
            XCTAssertGreaterThanOrEqual(button.frame.height + 0.01, 44, "Result action is too short: \(identifier)")
        }
    }

    private enum WindowOrientation: Equatable {
        case portrait
        case landscape
    }

    private func assertWindowOrientation(_ expected: WindowOrientation, in app: XCUIApplication) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let frame = window.frame
            let matches = expected == .portrait ? frame.height > frame.width : frame.width > frame.height
            if matches { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTFail("The app window did not rotate to \(expected): \(window.frame)")
    }

    private func assertFitsInWindow(_ element: XCUIElement, in app: XCUIApplication) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists)
        let visibleFrame = window.frame.insetBy(dx: -1, dy: -1)
        XCTAssertTrue(
            visibleFrame.contains(element.frame),
            "\(element.identifier) extends beyond the window: \(element.frame) vs \(window.frame)"
        )
    }

    private func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isHittable == true"),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func assertGameBoardDoesNotScroll(startButtonIdentifier: String) throws {
        let app = XCUIApplication()
        app.launch()

        let startButton = app.buttons[startButtonIdentifier]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        let buttonIsHittable = NSPredicate(format: "isHittable == true")
        expectation(for: buttonIsHittable, evaluatedWith: startButton)
        waitForExpectations(timeout: 5)
        startButton.tap()

        assertBoardCellsStayInPlace(in: app)
        keepScreenshot(named: "fixed-board-\(startButtonIdentifier)-portrait")

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        Thread.sleep(forTimeInterval: 0.5)
        assertBoardCellsStayInPlace(in: app)
        keepScreenshot(named: "fixed-board-\(startButtonIdentifier)-landscape")
    }

    private func assertBoardCellsStayInPlace(in app: XCUIApplication) {
        let topCell = app.buttons["boardCell-0-0"]
        let bottomCell = app.buttons["boardCell-7-7"]
        XCTAssertTrue(topCell.waitForExistence(timeout: 3))
        XCTAssertTrue(topCell.isHittable)
        XCTAssertTrue(bottomCell.isHittable)

        let topFrame = topCell.frame
        let bottomFrame = bottomCell.frame
        bottomCell.press(forDuration: 0.1, thenDragTo: topCell)

        XCTAssertEqual(topCell.frame.minY, topFrame.minY, accuracy: 1)
        XCTAssertEqual(bottomCell.frame.minY, bottomFrame.minY, accuracy: 1)
        XCTAssertTrue(topCell.isHittable)
        XCTAssertTrue(bottomCell.isHittable)
    }

    func testEnglishLocalizationIsDisplayed() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let twoPlayerButton = app.buttons["startTwoPlayerButton"]
        XCTAssertTrue(twoPlayerButton.waitForExistence(timeout: 5))
        XCTAssertEqual(twoPlayerButton.label, "Two Players")
    }

    func testKoreanLocalizationIsDisplayed() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()

        let twoPlayerButton = app.buttons["startTwoPlayerButton"]
        XCTAssertTrue(twoPlayerButton.waitForExistence(timeout: 5))
        XCTAssertEqual(twoPlayerButton.label, "2인 대전")
    }

    func testTrophyOpensRankingAndAchievementsChoices() throws {
        let app = XCUIApplication()
        app.launch()

        let trophyButton = app.buttons["showGameCenterMenuButton"]
        XCTAssertTrue(trophyButton.waitForExistence(timeout: 5))
        let buttonIsHittable = NSPredicate(format: "isHittable == true")
        expectation(for: buttonIsHittable, evaluatedWith: trophyButton)
        waitForExpectations(timeout: 3)
        trophyButton.tap()

        XCTAssertTrue(app.buttons["showOniLeaderboardButton"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["showAchievementsButton"].exists)

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Game Center choices"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testCaptureEnglishStoreScreenshots() throws {
        try captureStoreScreenshots(
            language: "en",
            locale: "en_US",
            fileNameLocale: "en",
            capturesAfterMove: true
        )
    }

    func testCaptureSimplifiedChineseStoreScreenshots() throws {
        try captureStoreScreenshots(language: "zh-Hans", locale: "zh_CN", fileNameLocale: "zh-hans")
    }

    func testCaptureBrazilianPortugueseStoreScreenshots() throws {
        try captureStoreScreenshots(language: "pt-BR", locale: "pt_BR", fileNameLocale: "pt-br")
    }

    func testCaptureFrenchStoreScreenshots() throws {
        try captureStoreScreenshots(language: "fr", locale: "fr_FR", fileNameLocale: "fr")
    }

    func testCaptureSpanishStoreScreenshots() throws {
        try captureStoreScreenshots(language: "es", locale: "es_ES", fileNameLocale: "es-es")
    }

    func testCaptureKoreanStoreScreenshots() throws {
        try captureStoreScreenshots(language: "ko", locale: "ko_KR", fileNameLocale: "ko")
    }

    private func captureStoreScreenshots(
        language: String,
        locale: String,
        fileNameLocale: String,
        capturesAfterMove: Bool = false
    ) throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        app.launch()

        let twoPlayerButton = app.buttons["startTwoPlayerButton"]
        XCTAssertTrue(twoPlayerButton.waitForExistence(timeout: 5))
        let menuIsHittable = NSPredicate(format: "isHittable == true")
        expectation(for: menuIsHittable, evaluatedWith: twoPlayerButton)
        waitForExpectations(timeout: 3)
        Thread.sleep(forTimeInterval: 3.0)
        keepScreenshot(named: "01-\(fileNameLocale)-menu")

        let easyCPUButton = app.buttons["startCPUButton-easy"]
        XCTAssertTrue(easyCPUButton.waitForExistence(timeout: 2))
        easyCPUButton.tap()

        let openingMove = app.buttons["boardCell-2-3"]
        XCTAssertTrue(openingMove.waitForExistence(timeout: 3))
        Thread.sleep(forTimeInterval: 2.0)
        keepScreenshot(named: "02-\(fileNameLocale)-cpu-start")

        if capturesAfterMove {
            openingMove.tap()
            Thread.sleep(forTimeInterval: 1.5)
            keepScreenshot(named: "03-\(fileNameLocale)-cpu-after-move")
        }
    }

    private func keepScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
