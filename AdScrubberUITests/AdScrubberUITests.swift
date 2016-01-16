//
//  AdScrubberUITests.swift
//  AdScrubberUITests
//
//  Created by David Westgate on 11/23/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//

import XCTest

class AdScrubberUITests: XCTestCase {
  
  let app = XCUIApplication()
  var table: XCUIElementQuery!
  var hostsFileURITextView: XCUIElement!
  var detectedFileTypeLabel: XCUIElement!
  var fileTypeLabel: XCUIElement!
  var entriesInBlocklistLabel: XCUIElement!
  var entryCountLabel: XCUIElement!
  var reloadButton: XCUIElement!
  var blockSubdomainsLabel: XCUIElement!
  var blocksubdomainsswitchSwitch: XCUIElement!
  var restoreDefaultSettingsButton: XCUIElement!
  
  // MARK: - This method is called before the invocation of each test method in the class.
  override func setUp() {
    super.setUp()
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    app.launch()
    table = app.tables
    hostsFileURITextView = table.textViews["hostsFileURI"]
    detectedFileTypeLabel = table.staticTexts["detectedFileTypeLabel"]
    fileTypeLabel = table.staticTexts["fileTypeLabel"]
    entriesInBlocklistLabel = table.staticTexts["entriesInBlocklistLabel"]
    entryCountLabel = table.staticTexts["entryCountLabel"]
    reloadButton = app.buttons["reloadButton"]
    blockSubdomainsLabel = table.staticTexts["blockSubdomainsLabel"]
    blocksubdomainsswitchSwitch = table.switches["blockSubdomainsSwitch"]
    restoreDefaultSettingsButton = app.buttons["restoreDefaultSettingsButton"]
  }
  
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  
  func test_A_UpdateSuccessful() {
    
    let expectedMessage = "Ad Scrubber blocklist successfully updated"
    
    self.setAlertExpectationWithMessage(expectedMessage)
    
    loadFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockCNN")
    app.alerts["Ad Scrubber Blocklist Reload"].collectionViews.buttons["OK"].tap()
    loadFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockDrudge")
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  
  func test_B_NoUpdateRequired() {
    
    let expectedMessage = "List already up-to-date"
    
    self.setAlertExpectationWithMessage(expectedMessage)
    
    loadFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockCNN")
    app.alerts["Ad Scrubber Blocklist Reload"].collectionViews.buttons["OK"].tap()
    loadFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockCNN")
    
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
    
    loadFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockCNN")
    app.alerts["Ad Scrubber Blocklist Reload"].collectionViews.buttons["OK"].tap()
    loadFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-empty")
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  
  private func setExpectation(message: String, app: XCUIApplication) {
    let visible = NSPredicate(format: "hittable == 1")
    self.expectationForPredicate(visible, evaluatedWithObject: app.staticTexts[message], handler: nil)
  }
  
  
  private func loadFile(text: String) {
    
    hostsFileURITextView.pressForDuration(1.55);
    app.menus.menuItems["Select All"].tap()
    hostsFileURITextView.typeText(text)
    // detectedFileTypeLabel.tap()
    reloadButton.tap()
  }

  
  private func setAlertExpectationWithMessage(message: String) {
    let exists = NSPredicate(format: "exists == 1")
    self.expectationForPredicate(exists, evaluatedWithObject:app.alerts["Ad Scrubber Blocklist Reload"].staticTexts[message], handler: nil)
  }

}
