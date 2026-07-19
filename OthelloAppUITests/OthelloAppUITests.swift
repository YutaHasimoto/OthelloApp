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
