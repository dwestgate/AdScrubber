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

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
  
  
    func anotherTest() {
    
      
      let app = XCUIApplication()
      
      let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1)
      let textView = element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.TextView).element
      textView.pressForDuration(2.1);
      app.menuItems["Select All"].tap()
      textView.typeText("https://nosuchdomain/nosuchpath")
      element.pressForDuration(0.5);
      app.buttons["Reload"].tap()
    
    }

/*
    func testNonexistantURI() {
      
      let app = XCUIApplication()

      let expectedText = "No updates to download"
      let testPredicate = NSPredicate(format: "label = '\(expectedText)'")
      
      let hostsFileURITextView = app.textViews["hostsFileURI"]
      let loadResultLabel = app.staticTexts["loadResult"]
      let reloadButton = app.buttons["reloadButton"]
      
      self.expectationForPredicate(testPredicate, evaluatedWithObject: loadResultLabel, handler: nil)
      
      let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1)
      let textView = element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.TextView).element
      textView.pressForDuration(2.1);
      app.menuItems["Select All"].tap()
      hostsFileURITextView.typeText("https://nosuchdomain/nosuchpath")
      element.pressForDuration(0.5);
      reloadButton.tap()
      
      self.waitForExpectationsWithTimeout(10, handler: nil)
    }
*/
/*
  func testOtherButtonChangesFooter() {
  let app = XCUIApplication()
  
  // Define the expectation on the final UI state
  //
  let expectedText = "Oh! Did something happen?!"
  let labelIdentifier = "footer label"
  let testPredicate = NSPredicate(format: "label = '\(expectedText)'")
  let object = app.staticTexts.elementMatchingType(.Any, identifier: labelIdentifier)
  
  self.expectationForPredicate(testPredicate, evaluatedWithObject: object, handler: nil)
  
  // Act on the UI to change the state
  //
  app.buttons["Press me and I'll do something, eventually"].tap()
  
  // Wait and see...
  //
  self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  
  XCUIElement *label = self.app.staticTexts[@"Hello, world!"];
  NSPredicate *exists = [NSPredicate predicateWithFormat:@"exists == 1"];
  
  [self expectationForPredicate:exists evaluatedWithObject:label handler:nil];
  [self waitForExpectationsWithTimeout:5 handler:nil];
  */
  
  func testTest() {
    
    let app = XCUIApplication()
    
    let control = app.staticTexts["loadResult"]
    let exists = NSPredicate(format: "exists == 1")
    
    self.expectationForPredicate(exists, evaluatedWithObject: control, handler: nil)
    let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1)
    let textView = element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.TextView).element
    textView.pressForDuration(2.1);
    app.menuItems["Select All"].tap()
    textView.typeText("https://nosuchdomain/nosuchpath")
    element.pressForDuration(0.5);
    app.buttons["reloadButton"].tap()
    
    self.waitForExpectationsWithTimeout(10, handler: nil)
    
    
  }
  
    
}
