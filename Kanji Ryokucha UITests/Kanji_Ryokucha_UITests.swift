//
//  Kanji_Ryokucha_UITests.swift
//  Kanji Ryokucha UITests
//
//  Created by German Buela on 4/29/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import XCTest

class Kanji_Ryokucha_UITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        
        let app = XCUIApplication()
        app.buttons["enterGuest"].tap()
        app.buttons["startGuest"].tap()
        app.buttons["topDue"].tap()
        app.buttons["startReview"].tap()
        app.buttons["flipCard"].tap()
        app.buttons["answerYes"].tap()
    }
    
    func testDraw() {
        let app = XCUIApplication()
        app.buttons["enterGuest"].tap()
        app.buttons["startGuest"].tap()
        app.buttons["topDue"].tap()
        app.buttons["startReview"].tap()
        let flipcardButton = app.buttons["flipCard"]
        flipcardButton.tap()
        
        let answeryesButton = app.buttons["answerYes"]
        answeryesButton.tap()
        flipcardButton.tap()
        answeryesButton.tap()
        flipcardButton.tap()
        answeryesButton.tap()
        app.staticTexts["draw kanji here"].swipeDown()
        
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
        element.swipeRight()
        element.swipeLeft()
        element.swipeRight()
        element.swipeRight()
        
    }
}
