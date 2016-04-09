//
//  AppDelegate.swift
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
import Branch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  // Respond to URI scheme links
  func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
    // pass the url to the handle deep link call
    Branch.getInstance().handleDeepLink(url);
    
    // do other deep link routing for the Facebook SDK, Pinterest SDK, etc
    return true
  }
  
  // Respond to Universal Links
  func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
    // pass the url to the handle deep link call
    
    return Branch.getInstance().continueUserActivity(userActivity)
  }

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    
    let branch: Branch = Branch.getInstance()
    branch.initSessionWithLaunchOptions(launchOptions, andRegisterDeepLinkHandler: { params, error in
      if (error == nil) {
        // params are the deep linked params associated with the link that the user clicked -> was re-directed to this app
        // params will be empty if no data found
        // ... insert custom logic here ...
        NSLog("params: %@", params.description)
      }
    })
    
    return true
  }

  func applicationWillResignActive(application: UIApplication) {
  }

  func applicationDidEnterBackground(application: UIApplication) {
  }

  func applicationWillEnterForeground(application: UIApplication) {
  }

  func applicationDidBecomeActive(application: UIApplication) {
  }

  func applicationWillTerminate(application: UIApplication) {
  }


}

