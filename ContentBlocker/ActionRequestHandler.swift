//
//  ActionRequestHandler.swift
//  ContentBlocker
//
//  Created by David Westgate on 11/23/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//
import UIKit
import MobileCoreServices

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
  
  func beginRequestWithExtensionContext(context: NSExtensionContext) {

    var logfile = ""

    let sharedPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.refabricants.adscrubber")! as NSURL
    
    var contentBlockingRules = sharedPath.URLByAppendingPathComponent("blockerList.json")
    
    let defaults = NSUserDefaults.init(suiteName: "group.com.refabricants.adscrubber")
    
    if defaults!.boolForKey("isBlockingSubdomains") == true {
      contentBlockingRules = sharedPath.URLByAppendingPathComponent("wildcardBlockerList.json")
      logfile += "Using wildcardBlockerList.json\n"
    }
    
    logfile += "Using path: \(contentBlockingRules.path)"
    
    var attachment: NSItemProvider
    logfile += "contentBlockingRules = \(contentBlockingRules.description)\n"
    
    var error:NSError?
    if contentBlockingRules.checkResourceIsReachableAndReturnError(&error) {
      attachment = NSItemProvider(contentsOfURL: contentBlockingRules)!
      logfile += "Custom rules will be used\n"
    } else {
      attachment = NSItemProvider(contentsOfURL: NSBundle.mainBundle().URLForResource("blockerList", withExtension: "json"))!
      logfile += "Using built-in rules\n"
    }
    
    logfile += attachment.description + "\n"
    let item = NSExtensionItem()
    item.attachments = [attachment]
    
    context.completeRequestReturningItems([item], completionHandler: nil);
    
    let logFile = sharedPath.URLByAppendingPathComponent("log.txt")
    
    if NSFileManager().fileExistsAtPath(logFile.path!) {
      logfile += "The Finished file already exists at path - deleting\n"
      do {
        try NSFileManager.defaultManager().removeItemAtPath(logFile.path!)
      } catch {
        logfile += "No Finished file to delete\n"
      }
    }
    
    logfile += "Finished file written successfully\n"
    do {
      try logfile.writeToFile(logFile.path!, atomically: false, encoding: NSUTF8StringEncoding)
    } catch {
    }
    
  }
  
}
