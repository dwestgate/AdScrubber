//
//  AdScrubberUITests.swift
//  AdScrubberUITests
//
//  Created by David Westgate on 11/23/15.
//  Copyright © 2016 Refabricants. All rights reserved.
//

import XCTest

class AdScrubberUITests: XCTestCase {
  
  let app = XCUIApplication()
  var adScrubberButton: XCUIElement!
  var table: XCUIElementQuery!
  var blacklistURLTextView: XCUIElement!
  var blocklistFileTypeLabel: XCUIElement!
  var fileTypeLabel: XCUIElement!
  var entriesInBlocklistLabel: XCUIElement!
  var entryCountLabel: XCUIElement!
  var reloadButton: XCUIElement!
  var blockSubdomainsLabel: XCUIElement!
  var blockSubdomainsswitchSwitch: XCUIElement!
  var useCustomBlocklistSwitch: XCUIElement!
  var restoreDefaultSettingsButton: XCUIElement!
  var cancelButton: XCUIElement!
  
  // MARK: - This method is called before the invocation of each test method in the class.
  override func setUp() {
    super.setUp()
    
    continueAfterFailure = false

    app.launch()
    table = app.tables
    adScrubberButton = app.navigationBars["AdScrubber.blacklistURLView"].buttons["Ad Scrubber"]
    blacklistURLTextView = table.textViews["blacklistURL"]
    blocklistFileTypeLabel = table.staticTexts["blocklistFileTypeLabel"]
    fileTypeLabel = table.staticTexts["fileTypeLabel"]
    entriesInBlocklistLabel = table.staticTexts["entriesInBlocklistLabel"]
    entryCountLabel = table.staticTexts["entryCountLabel"]
    reloadButton = app.buttons["reloadButton"]
    blockSubdomainsLabel = table.staticTexts["blockSubdomainsLabel"]
    blockSubdomainsswitchSwitch = table.switches["blockSubdomainsSwitch"]
    useCustomBlocklistSwitch = table.switches["useCustomBlocklistSwitch"]
    restoreDefaultSettingsButton = app.buttons["restoreDefaultSettingsButton"]
    cancelButton = table.buttons["cancelButton"]
  }
  
  
  override func tearDown() {
    super.tearDown()
  }
  
  
  func test_A_UpdateSuccessful() {
    
    let expectedMessage = "Ad Scrubber blocklist successfully updated"
    
    self.setAlertExpectationWithMessage(expectedMessage)
    loadFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockDrudge")
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  
  func test_B_NoUpdateRequired() {
    
    let expectedMessage = "List already up-to-date"
    
    self.setAlertExpectationWithMessage(expectedMessage)
    
    loadFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockCNN")
    app.alerts["Ad Scrubber Blocklist Reload"].collectionViews.buttons["OK"].tap()
    reloadButton.tap()
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  
  func test_C_NotHTTPS() {
    
    let expectedMessage = "Error: link must be https"
    
    self.setAlertExpectationWithMessage(expectedMessage)
    
    loadFile("http://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockDrudge")
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  
  func test_D_InvalidURL() {
    
    let expectedMessage = "Supplied URL is invalid"
    
    self.setAlertExpectationWithMessage(expectedMessage)
    
    loadFile("https://nosuc\\hdomain/nosuchpath")
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  
  func test_E_ServerNotFound() {
    
    let expectedMessage = "Unable to contact server"
    
    self.setExpectation(expectedMessage, app: app)
    
    loadFile("https://nosuchserver")
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }

  
  func test_F_NoSuchFile() {
    
    let expectedMessage = "File not found"
    
    self.setExpectation(expectedMessage, app: app)
    
    loadFile("https://raw.githubusercontent.com/nosuchfileexists")
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  
  func test_G_EmptyFile() {
    
    let expectedMessage = "Ad Scrubber blocklist successfully updated"
    
    self.setAlertExpectationWithMessage(expectedMessage)
    
    loadFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-empty")
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  
  private func setExpectation(message: String, app: XCUIApplication) {
    let visible = NSPredicate(format: "hittable == 1")
    self.expectationForPredicate(visible, evaluatedWithObject: app.staticTexts[message], handler: nil)
  }
  
  
  private func loadFile(text: String) {
    restoreDefaultSettingsButton.tap()
    blacklistURLTextView.tap()
    cancelButton.tap()
    blacklistURLTextView.typeText(text)
    adScrubberButton.tap()
    useCustomBlocklistSwitch.tap()
  }
  
  
  private func setAlertExpectationWithMessage(message: String) {
    let exists = NSPredicate(format: "exists == 1")
    self.expectationForPredicate(exists, evaluatedWithObject:app.alerts["Ad Scrubber Blocklist Reload"].staticTexts[message], handler: nil)
  }

}
