//
//  ActionRequestHandler.swift
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

import UIKit
import MobileCoreServices

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
  
  func beginRequestWithExtensionContext(context: NSExtensionContext) {

    var error:NSError?
    // var logfile = ""

    let appBundle = NSBundle.mainBundle()
    let sharedPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.refabricants.adscrubber")! as NSURL
    let defaults = NSUserDefaults.init(suiteName: "group.com.refabricants.adscrubber")
    
    var blockerList: String
    
    if defaults!.boolForKey("isBlockSubdomainsOn") == true {
      blockerList = "wildcardBlockerList"
      
      // logfile += "Using wildcardBlockerList.json\n"
    } else {
      blockerList = "blockerList"
      // logfile += "Using blockerList.json\n"
    }
    // logfile += "Using: \(blockerList)\n"
    
    let contentBlockingRules = sharedPath.URLByAppendingPathComponent("\(blockerList).json")
    var attachment: NSItemProvider
    
    if (defaults!.boolForKey("isUseCustomBlocklistOn") == true) && (contentBlockingRules.checkResourceIsReachableAndReturnError(&error)) {
      attachment = NSItemProvider(contentsOfURL: contentBlockingRules)!
      // logfile += "Using custom rules\n"
    } else {
      attachment = NSItemProvider(contentsOfURL: appBundle.URLForResource(blockerList, withExtension: "json"))!
      // logfile += "Using built-in rules\n"
    }
    
    let item = NSExtensionItem()
    item.attachments = [attachment]
    context.completeRequestReturningItems([item], completionHandler: nil);
    
    let logFile = sharedPath.URLByAppendingPathComponent("log.txt")
    
    if NSFileManager().fileExistsAtPath(logFile.path!) {
      do {
        try NSFileManager.defaultManager().removeItemAtPath(logFile.path!)
      } catch {
      }
    }
    
    /*
    do {
      try logfile.writeToFile(logFile.path!, atomically: false, encoding: NSUTF8StringEncoding)
    } catch {
    }*/
    
  }
  
}
