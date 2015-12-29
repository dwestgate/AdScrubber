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
    
    let expectedMessage = "updateSuccessfulLabel"
    let app = XCUIApplication()
    
    self.setExpectation(expectedMessage, app: app)
    
    loadHostsFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockCNN", app: app)
    loadHostsFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockDrudge", app: app)
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
    self.verifyLabelsAreHidden(expectedMessage, app: app)
  }
  
  
  func test_B_NoUpdateRequired() {
    
    let expectedMessage = "noUpdateRequiredLabel"
    let app = XCUIApplication()
    
    self.setExpectation(expectedMessage, app: app)
    
    loadHostsFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockCNN", app: app)
    loadHostsFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockCNN", app: app)
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
    self.verifyLabelsAreHidden(expectedMessage, app: app)
  }
  
  
  func test_C_NotHTTPS() {
    
    let expectedMessage = "notHTTPSLabel"
    let app = XCUIApplication()
    
    self.setExpectation(expectedMessage, app: app)
    
    loadHostsFile("http://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockDrudge", app: app)
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
    self.verifyLabelsAreHidden(expectedMessage, app: app)
    
  }
  
  func test_D_InvalidURL() {
    
    let expectedMessage = "invalidURLLabel"
    let app = XCUIApplication()
    
    self.setExpectation(expectedMessage, app: app)
    
    loadHostsFile("https://nosuc\\hdomain/nosuchpath", app: app)
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
    self.verifyLabelsAreHidden(expectedMessage, app: app)
    
  }
  
  
  func test_E_ServerNotFound() {
    
    let expectedMessage = "serverNotFoundLabel"
    let app = XCUIApplication()
    
    self.setExpectation(expectedMessage, app: app)
    
    loadHostsFile("https://nosuchserver", app: app)
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
    self.verifyLabelsAreHidden(expectedMessage, app: app)
    
  }

  
  func test_F_NoSuchFile() {
    
    let expectedMessage = "noSuchFileLabel"
    let app = XCUIApplication()
    
    self.setExpectation(expectedMessage, app: app)
    
    loadHostsFile("https://raw.githubusercontent.com/nosuchfileexists", app: app)
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
    self.verifyLabelsAreHidden(expectedMessage, app: app)
 
  }
  
  
  func test_G_EmptyFile() {
    
    let expectedMessage = "updateSuccessfulLabel"
    let app = XCUIApplication()
    
    self.setExpectation(expectedMessage, app: app)
    
    loadHostsFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockCNN", app: app)
    loadHostsFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-empty", app: app)
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
    self.verifyLabelsAreHidden(expectedMessage, app: app)
  }
  
  
  func test_G_UpdateSuccessful() {
    
    let expectedMessage = "updateSuccessfulLabel"
    let app = XCUIApplication()
    
    self.setExpectation(expectedMessage, app: app)
    
    loadHostsFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockCNN", app: app)
    loadHostsFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockDrudge", app: app)
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
    self.verifyLabelsAreHidden(expectedMessage, app: app)
  }
  
  
  private func loadHostsFile(text: String, app: XCUIApplication) {
    let element = app.otherElements.containingType(.NavigationBar, identifier:"Blackhole").childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element
    let hostsFileURITextView = app.textViews["hostsFileURI"]
    let reloadButton = app.buttons["reloadButton"]
    
    hostsFileURITextView.pressForDuration(0.55);
    app.menuItems["Select All"].tap()
    hostsFileURITextView.typeText(text)
    element.tap()
    reloadButton.tap()
  }
  
  
  private func setExpectation(message: String, app: XCUIApplication) {
    let visible = NSPredicate(format: "hittable == 1")
    self.expectationForPredicate(visible, evaluatedWithObject: app.staticTexts[message], handler: nil)
  }
  
  
  private func verifyLabelsAreHidden(expectedMessage: String, app: XCUIApplication) {
    
    let messages = ["UpdateSuccessful",
                    "NoUpdateRequired",
                    "NotHTTPS",
                    "InvalidURL",
                    "ServerNotFound",
                    "NoSuchFile",
                    "EmptyFile"]
    let hidden = NSPredicate(format: "hittable == 0")
    
    for message in messages {
      if message != expectedMessage {
        self.expectationForPredicate(hidden, evaluatedWithObject: app.staticTexts[message], handler: nil)
        self.waitForExpectationsWithTimeout(0, handler: nil)
      }
    }
  }

}
