//
//  ViewController.swift
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

import Foundation
import UIKit
import SafariServices

/// Controls the user interface for ineracting with the Ad Scrubber blocklist
class ViewController: UITableViewController {
  
  // MARK: -
  // MARK: Control Outlets
  @IBOutlet weak var useCustomBlocklistLabel: UILabel!
  @IBOutlet weak var useCustomBlocklistSwitch: UISwitch!
  @IBOutlet weak var blacklistURLTextView: UITextView!
  @IBOutlet weak var blocklistFileTypeLabel: UILabel!
  @IBOutlet weak var typeLabel: UILabel!
  @IBOutlet weak var entryCountLabel: UILabel!
  @IBOutlet weak var blockSubdomainsLabel: UILabel!
  @IBOutlet weak var blockSubdomainsSwitch: UISwitch!
  @IBOutlet weak var restoreDefaultSettingsButton: UIButton!
  @IBOutlet weak var reloadButton: UIButton!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  // MARK: Variables
  /// Convenience var for referencing the main queue
  private var GCDMainQueue: dispatch_queue_t {
    return dispatch_get_main_queue()
  }
  
  /// Convenience var for referencing the high priority queue
  private var GCDUserInteractiveQueue: dispatch_queue_t {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
  }
  
  /// Convenience var for referencing the default priority queue
  private var GCDUserInitiatedQueue: dispatch_queue_t {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
  }
  
  /// Convenience var for referencing the low priority queue
  private var GCDUtilityQueue: dispatch_queue_t {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
  }
  
  /// Convenience var for referencing the background queue
  private var GCDBackgroundQueue: dispatch_queue_t {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
  }
  
  // MARK: Overridden functions
  override func viewDidLoad() {
    super.viewDidLoad()
    
    blacklistURLTextView.userInteractionEnabled = false
  }
  
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    if (BlackholeList.currentBlacklist.getValueForKey("URL") == nil) {
      setDefaultValues()
    }
    refreshControls()
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
    BlackholeList.setIsUseCustomBlocklistOn(false)
    disableCustomBlocklist()
    refreshControls()
  }
  
  
  // MARK: Control Actions
  @IBAction func unwind(unwindSegue: UIStoryboardSegue) {
  }
  
  
  @IBAction func blockSubdomainsSwitchValueChanged(sender: AnyObject) {
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
    BlackholeList.setIsBlockingSubdomains(blockSubdomainsSwitch.on)
    
    SFContentBlockerManager.reloadContentBlockerWithIdentifier(
      "com.refabricants.AdScrubber.ContentBlocker", completionHandler: {
        (error: NSError?) in print("Reload complete\n")})
  }
  
  
  @IBAction func useCustomBlocklistSwitchValueChanged(sender: AnyObject) {
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
    BlackholeList.setIsUseCustomBlocklistOn(useCustomBlocklistSwitch.on)
    print("useCustomBLocklistSwitchOn = \(useCustomBlocklistSwitch.on)")
    if (useCustomBlocklistSwitch.on) {
      reloadButtonPressed(self)
    } else {
      disableCustomBlocklist()
      refreshControls()
    }
    
  }
  
  
  @IBAction func reloadButtonPressed(sender: AnyObject) {
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
    activityIndicator.startAnimating()
    
    dispatch_async(GCDUserInteractiveQueue, { () -> Void in
      
      do {
        try self.refreshBlockList()
      } catch ListUpdateStatus.NotHTTPS {
        self.showMessageWithStatus(.NotHTTPS)
        dispatch_async(self.GCDMainQueue, { () -> Void in
          self.disableCustomBlocklist()
          self.refreshControls()
        })
      } catch ListUpdateStatus.InvalidURL {
        self.showMessageWithStatus(.InvalidURL)
        dispatch_async(self.GCDMainQueue, { () -> Void in
          self.disableCustomBlocklist()
          self.refreshControls()
        })
      } catch {
        self.showMessageWithStatus(.UnexpectedDownloadError)
        dispatch_async(self.GCDMainQueue, { () -> Void in
          self.disableCustomBlocklist()
          self.refreshControls()
        })
      }
    });
  }
  
  
  @IBAction func restoreDefaultSettingsTouchUpInside(sender: AnyObject) {
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
    setDefaultValues()
    refreshControls()
  }
  
  
  // MARK: Private Functions
  /**
  
  */
  private func refreshBlockList() throws {
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
    guard blacklistURLTextView.text.lowercaseString.hasPrefix("https://") else {
      throw ListUpdateStatus.NotHTTPS
    }
    guard let hostsFile = NSURL(string: blacklistURLTextView.text) else {
      throw ListUpdateStatus.InvalidURL
    }
    
    BlackholeList.validateURL(hostsFile, completion: { (var updateStatus) -> () in
      defer {
        self.refreshControls()
        self.showMessageWithStatus(updateStatus)
        if (updateStatus != .UpdateSuccessful && updateStatus != .TooManyEntries && updateStatus != .NoUpdateRequired) {
          dispatch_async(self.GCDMainQueue, { () -> Void in
            self.disableCustomBlocklist()
            self.refreshControls()
          })
        }
      }
      
      guard updateStatus == ListUpdateStatus.UpdateSuccessful else {
        return
      }
      
      do {
        let blockList = try BlackholeList.downloadBlocklist(hostsFile)
        let createBlockerListJSONResult = BlackholeList.createBlockerListJSON(blockList!)
        updateStatus = createBlockerListJSONResult.updateStatus
        if (updateStatus == .UpdateSuccessful || updateStatus == .TooManyEntries) {
          
          BlackholeList.currentBlacklist.setValueWithKey(createBlockerListJSONResult.blacklistFileType!, forKey: "FileType")
          BlackholeList.currentBlacklist.setValueWithKey("\(createBlockerListJSONResult.numberOfEntries!)", forKey: "EntryCount")
          BlackholeList.currentBlacklist.setValueWithKey(hostsFile.absoluteString, forKey: "URL")
          print("setting blockerListURL default to: \(hostsFile.absoluteString)")
          BlackholeList.candidateBlacklist.removeAllValues()

          SFContentBlockerManager.reloadContentBlockerWithIdentifier("com.refabricants.AdScrubber.ContentBlocker", completionHandler: {
            (error: NSError?) in print("Reload complete\n")})
        }
      } catch {
        if updateStatus == .UpdateSuccessful {
          updateStatus = ListUpdateStatus.UnableToReplaceExistingBlockerlist
        }
        return
      }
    })
  }
  
  
  private func showMessageWithStatus(status: ListUpdateStatus) {
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
    dispatch_async(GCDMainQueue, { () -> Void in
      self.activityIndicator.stopAnimating()
      
      let alert = UIAlertController(title: "Ad Scrubber Blocklist Reload", message: status.rawValue, preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
      
    })
  }
  
  
  private func refreshControls() {
    print("\n>>> Entering: \(__FUNCTION__) <<<")
    print("Type of list        : \(BlackholeList.getDownloadedBlacklistType())")
    print("Using custom blocklist  : \(BlackholeList.getIsUseCustomBlocklistOn())")
    print("Blocking subdomains     : \(BlackholeList.getIsBlockingSubdomains())\n")
    print("preloaded URL           : \(BlackholeList.preloadedBlacklist.getValueForKey("URL"))")
    print("preloaded FileType      : \(BlackholeList.preloadedBlacklist.getValueForKey("FileType"))")
    print("preloaded EntryCount: \(BlackholeList.preloadedBlacklist.getValueForKey("EntryCount"))")
    print("preloaded Etag: \(BlackholeList.preloadedBlacklist.getValueForKey("Etag"))")
    print("current URL          : \(BlackholeList.currentBlacklist.getValueForKey("URL"))")
    print("current FileType     : \(BlackholeList.currentBlacklist.getValueForKey("FileType"))")
    print("current EntryCount   : \(BlackholeList.currentBlacklist.getValueForKey("EntryCount"))")
    print("current Etag   : \(BlackholeList.currentBlacklist.getValueForKey("Etag"))")
    print("candidate URL       : \(BlackholeList.candidateBlacklist.getValueForKey("URL"))")
    print("candidate FileType  : \(BlackholeList.candidateBlacklist.getValueForKey("FileType"))")
    print("candidate EntryCount: \(BlackholeList.candidateBlacklist.getValueForKey("EntryCount"))")
    print("candidate Etag: \(BlackholeList.candidateBlacklist.getValueForKey("Etag"))")
    print("displayed URL          : \(BlackholeList.displayedBlacklist.getValueForKey("URL"))")
    print("displayed FileType     : \(BlackholeList.displayedBlacklist.getValueForKey("FileType"))")
    print("displayed EntryCount   : \(BlackholeList.displayedBlacklist.getValueForKey("EntryCount"))")
    print("displayed Etag   : \(BlackholeList.displayedBlacklist.getValueForKey("Etag"))")
    
    useCustomBlocklistSwitch.setOn(BlackholeList.getIsUseCustomBlocklistOn(), animated: true)
    
    blacklistURLTextView.text = BlackholeList.displayedBlacklist.getValueForKey("URL")
    typeLabel.text = BlackholeList.currentBlacklist.getValueForKey("FileType")
    entryCountLabel.text = BlackholeList.currentBlacklist.getValueForKey("EntryCount")
    
    blockSubdomainsSwitch.setOn(BlackholeList.getIsBlockingSubdomains(), animated: true)
    
    if (BlackholeList.getIsUseCustomBlocklistOn()) {
      blacklistURLTextView.textColor = UIColor.darkGrayColor()
      reloadButton.enabled = true
      
      if (BlackholeList.currentBlacklist.getValueForKey("FileType") == "JSON") {
        BlackholeList.setIsBlockingSubdomains(false)
        blockSubdomainsSwitch.setOn(false, animated: true)
        blockSubdomainsSwitch.enabled = false
        blockSubdomainsLabel.enabled = false
      } else {
        blockSubdomainsSwitch.setOn(true, animated: true)
        blockSubdomainsSwitch.enabled = true
        blockSubdomainsLabel.enabled = true
      }
      
    } else {
      blockSubdomainsSwitch.enabled = true
      blockSubdomainsLabel.enabled = true
      blacklistURLTextView.textColor = UIColor.lightGrayColor()
      reloadButton.enabled = false
    }
    
  }
  
  
  private func disableCustomBlocklist() {
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
    let defaultURL = BlackholeList.preloadedBlacklist.getValueForKey("URL")
    let defaultFileType = BlackholeList.preloadedBlacklist.getValueForKey("FileType")
    let defaultEntryCount = BlackholeList.preloadedBlacklist.getValueForKey("EntryCount")
    let defaultEtag = BlackholeList.preloadedBlacklist.getValueForKey("Etag")
    
    BlackholeList.setIsUseCustomBlocklistOn(false)
    
    BlackholeList.currentBlacklist.setValueWithKey(defaultURL!, forKey: "URL")
    BlackholeList.currentBlacklist.setValueWithKey(defaultFileType!, forKey: "FileType")
    BlackholeList.currentBlacklist.setValueWithKey(defaultEntryCount!, forKey: "EntryCount")
    BlackholeList.currentBlacklist.setValueWithKey(defaultEtag!, forKey: "Etag")
    
    SFContentBlockerManager.reloadContentBlockerWithIdentifier(
      "com.refabricants.AdScrubber.ContentBlocker", completionHandler: {
        (error: NSError?) in print("Reload complete\n")})
  }


  private func setDefaultValues() {
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
    let defaultURL = BlackholeList.preloadedBlacklist.getValueForKey("URL")
    let defaultFileType = BlackholeList.preloadedBlacklist.getValueForKey("FileType")
    let defaultEntryCount = BlackholeList.preloadedBlacklist.getValueForKey("EntryCount")
    let defaultEtag = BlackholeList.preloadedBlacklist.getValueForKey("Etag")
    
    BlackholeList.candidateBlacklist.removeAllValues()
    
    BlackholeList.currentBlacklist.setValueWithKey(defaultURL!, forKey: "URL")
    BlackholeList.currentBlacklist.setValueWithKey(defaultFileType!, forKey: "FileType")
    BlackholeList.currentBlacklist.setValueWithKey(defaultEntryCount!, forKey: "EntryCount")
    BlackholeList.currentBlacklist.setValueWithKey(defaultEtag!, forKey: "Etag")
    
    BlackholeList.displayedBlacklist.removeAllValues()
    BlackholeList.displayedBlacklist.setValueWithKey(defaultURL!, forKey: "URL")
    
    BlackholeList.setIsBlockingSubdomains(false)
    BlackholeList.setIsUseCustomBlocklistOn(false)
  }
  
  
}