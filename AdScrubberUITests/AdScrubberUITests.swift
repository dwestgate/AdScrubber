//
//  AdScrubberUITests.swift
//  AdScrubber
//
//  Created by David Westgate on 12/31/15.
//  Copyright © 2016 David Westgate
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions: The above copyright
// notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE

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
    
    self.waitForExpectations(timeout: 10, handler: nil)
  }
  
  
  func test_B_NoUpdateRequired() {
    
    let expectedMessage = "List already up-to-date"
    
    self.setAlertExpectationWithMessage(expectedMessage)
    
    loadFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockCNN")
    app.alerts["Ad Scrubber Blocklist Reload"].collectionViews.buttons["OK"].tap()
    reloadButton.tap()
    
    self.waitForExpectations(timeout: 10, handler: nil)
  }
  
  
  func test_C_NotHTTPS() {
    
    let expectedMessage = "Error: link must be https"
    
    self.setAlertExpectationWithMessage(expectedMessage)
    
    loadFile("http://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-blockDrudge")
    
    self.waitForExpectations(timeout: 10, handler: nil)
  }
  
  
  func test_D_InvalidURL() {
    
    let expectedMessage = "Supplied URL is invalid"
    
    self.setAlertExpectationWithMessage(expectedMessage)
    
    loadFile("https://nosuc\\hdomain/nosuchpath")
    
    self.waitForExpectations(timeout: 10, handler: nil)
  }
  
  
  func test_E_ServerNotFound() {
    
    let expectedMessage = "Unable to contact server"
    
    self.setExpectation(expectedMessage, app: app)
    
    loadFile("https://nosuchserver")
    
    self.waitForExpectations(timeout: 10, handler: nil)
  }

  
  func test_F_NoSuchFile() {
    
    let expectedMessage = "File not found"
    
    self.setExpectation(expectedMessage, app: app)
    
    loadFile("https://raw.githubusercontent.com/nosuchfileexists")
    
    self.waitForExpectations(timeout: 10, handler: nil)
  }
  
  
  func test_G_EmptyFile() {
    
    let expectedMessage = "Ad Scrubber blocklist successfully updated"
    
    self.setAlertExpectationWithMessage(expectedMessage)
    
    loadFile("https://raw.githubusercontent.com/dwestgate/blackhole-testing/master/hosts-empty")
    
    self.waitForExpectations(timeout: 10, handler: nil)
  }
  
  
  fileprivate func setExpectation(_ message: String, app: XCUIApplication) {
    let visible = NSPredicate(format: "hittable == 1")
    self.expectation(for: visible, evaluatedWith: app.staticTexts[message], handler: nil)
  }
  
  
  fileprivate func loadFile(_ text: String) {
    restoreDefaultSettingsButton.tap()
    blacklistURLTextView.tap()
    cancelButton.tap()
    blacklistURLTextView.typeText(text)
    adScrubberButton.tap()
    useCustomBlocklistSwitch.tap()
  }
  
  
  fileprivate func setAlertExpectationWithMessage(_ message: String) {
    let exists = NSPredicate(format: "exists == 1")
    self.expectation(for: exists, evaluatedWith:app.alerts["Ad Scrubber Blocklist Reload"].staticTexts[message], handler: nil)
  }

}
