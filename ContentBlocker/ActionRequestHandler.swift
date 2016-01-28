//
//  ActionRequestHandler.swift
//  ContentBlocker
//
//  Created by David Westgate on 11/23/15.
//  Copyright © 2016 Refabricants. All rights reserved.
//
import UIKit
import MobileCoreServices

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
  
  func beginRequestWithExtensionContext(context: NSExtensionContext) {

    var error:NSError?
    var logfile = ""

    let appBundle = NSBundle.mainBundle()
    let sharedPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.refabricants.adscrubber")! as NSURL
    let defaults = NSUserDefaults.init(suiteName: "group.com.refabricants.adscrubber")
    
    var blockerList: String
    
    if defaults!.boolForKey("isBlockSubdomainsOn") == true {
      blockerList = "wildcardBlockerList"
      
      logfile += "Using wildcardBlockerList.json\n"
    } else {
      blockerList = "blockerList"
      logfile += "Using blockerList.json\n"
    }
    logfile += "Using: \(blockerList)\n"
    
    let contentBlockingRules = sharedPath.URLByAppendingPathComponent("\(blockerList).json")
    var attachment: NSItemProvider
    
    if (defaults!.boolForKey("isUseCustomBlocklistOn") == true) && (contentBlockingRules.checkResourceIsReachableAndReturnError(&error)) {
      attachment = NSItemProvider(contentsOfURL: contentBlockingRules)!
      logfile += "Using custom rules\n"
    } else {
      attachment = NSItemProvider(contentsOfURL: appBundle.URLForResource(blockerList, withExtension: "json"))!
      logfile += "Using built-in rules\n"
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
    
    do {
      try logfile.writeToFile(logFile.path!, atomically: false, encoding: NSUTF8StringEncoding)
    } catch {
    }
    
  }
  
}
