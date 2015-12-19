//
//  BlackholeUITests.swift
//  BlackholeUITests
//
//  Created by David Westgate on 11/23/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//

import XCTest

class BlackholeUITests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    XCUIApplication().launch()
    
  }
  
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  
  func test_A_UpdateSuccessful() {
    
    let app = XCUIApplication()
    
    let testInput = "https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockDrudge"
    let testResult = app.staticTexts["updateSuccessfulLabel"]
    
    let exists = NSPredicate(format: "hittable == 1")
    self.expectationForPredicate(exists, evaluatedWithObject: testResult, handler: nil)
    
    let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1)
    let textView = element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.TextView).element
    
    // Load small test file
    textView.pressForDuration(0.55);
    app.menuItems["Select All"].tap()
    textView.typeText("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockCNN")
    element.pressForDuration(0.5);
    app.buttons["reloadButton"].tap()
    
    // Load real file for test
    textView.pressForDuration(0.55);
    app.menuItems["Select All"].tap()
    textView.typeText(testInput)
    element.pressForDuration(0.5);
    app.buttons["reloadButton"].tap()
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  
  func test_B_NoUpdateRequired() {
    
    let app = XCUIApplication()
    
    let testInput = "https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockCNN"
    let testResult = app.staticTexts["noUpdateRequiredLabel"]
    
    let exists = NSPredicate(format: "hittable == 1")
    self.expectationForPredicate(exists, evaluatedWithObject: testResult, handler: nil)
    
    let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1)
    let textView = element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.TextView).element
    
    // Load test file once
    textView.pressForDuration(0.55);
    app.menuItems["Select All"].tap()
    textView.typeText(testInput)
    element.pressForDuration(0.5);
    app.buttons["reloadButton"].tap()
    
    // Load it a second time
    textView.pressForDuration(0.55);
    app.menuItems["Select All"].tap()
    textView.typeText(testInput)
    element.pressForDuration(0.5);
    app.buttons["reloadButton"].tap()
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  
  func test_C_NotHTTPS() {
    
    let app = XCUIApplication()
    
    let testInput = "http://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockDrudge"
    let testResult = app.staticTexts["notHTTPSLabel"]
    
    let exists = NSPredicate(format: "hittable == 1")
    self.expectationForPredicate(exists, evaluatedWithObject: testResult, handler: nil)
    
    let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1)
    let textView = element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.TextView).element
    textView.pressForDuration(0.55);
    app.menuItems["Select All"].tap()
    textView.typeText(testInput)
    element.pressForDuration(0.5);
    app.buttons["reloadButton"].tap()
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  func test_D_InvalidURL() {
    
    let app = XCUIApplication()
    
    print(app.debugDescription)
    
    let testInput = "https://nosuc\\hdomain/nosuchpath"
    let testResult = app.staticTexts["invalidURLLabel"]
    
    let exists = NSPredicate(format: "hittable == 1")
    self.expectationForPredicate(exists, evaluatedWithObject: testResult, handler: nil)
    
    let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1)
    let textView = element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.TextView).element
    textView.pressForDuration(0.55);
    app.menuItems["Select All"].tap()
    textView.typeText(testInput)
    element.pressForDuration(0.5);
    app.buttons["reloadButton"].tap()
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  
  func test_E_ServerNotFound() {
    
    let app = XCUIApplication()
    
    print(app.debugDescription)
    
    let testInput = "https://nosuchserver"
    let testResult = app.staticTexts["serverNotFoundLabel"]
    
    let exists = NSPredicate(format: "hittable == 1")
    self.expectationForPredicate(exists, evaluatedWithObject: testResult, handler: nil)
    
    let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1)
    let textView = element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.TextView).element
    textView.pressForDuration(0.55);
    app.menuItems["Select All"].tap()
    textView.typeText(testInput)
    element.pressForDuration(0.5);
    app.buttons["reloadButton"].tap()
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }

  
  func test_F_NoSuchFile() {
    
    let app = XCUIApplication()
    
    print(app.debugDescription)
    
    let testInput = "https://raw.githubusercontent.com/nosuchfileexists"
    let testResult = app.staticTexts["noSuchFileLabel"]
    
    let exists = NSPredicate(format: "hittable == 1")
    self.expectationForPredicate(exists, evaluatedWithObject: testResult, handler: nil)
    
    let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1)
    let textView = element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.TextView).element
    textView.pressForDuration(0.55);
    app.menuItems["Select All"].tap()
    textView.typeText(testInput)
    element.pressForDuration(0.5);
    app.buttons["reloadButton"].tap()
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
}
