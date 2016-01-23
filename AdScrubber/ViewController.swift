//
//  ViewController.swift
//  AdScrubber
//
//  Created by David Westgate on 12/31/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

class ViewController: UITableViewController {
  
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
  
  
  var GCDMainQueue: dispatch_queue_t {
    return dispatch_get_main_queue()
  }
  
  var GCDUserInteractiveQueue: dispatch_queue_t {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
  }
  
  var GCDUserInitiatedQueue: dispatch_queue_t {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
  }
  
  var GCDUtilityQueue: dispatch_queue_t {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
  }
  
  var GCDBackgroundQueue: dispatch_queue_t {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    blacklistURLTextView.userInteractionEnabled = false
  }
  
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    refreshControls()
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  
  @IBAction func useCustomBlocklistSwitchValueChanged(sender: AnyObject) {
    BlackholeList.setIsUseCustomBlocklistOn(self.useCustomBlocklistSwitch.on)
    refreshControls()
  }
  
  
  @IBAction func reloadButtonPressed(sender: AnyObject) {
    
    activityIndicator.startAnimating()
    
    dispatch_async(GCDUserInteractiveQueue, { () -> Void in
      
      do {
        try self.refreshBlockList()
      } catch ListUpdateStatus.NotHTTPS {
        self.showMessageWithStatus(.NotHTTPS)
        /* dispatch_async(self.GCDMainQueue, { () -> Void in
          self.blacklistURLTextView.text = BlackholeList.getBlacklistURL()
        })*/
      } catch ListUpdateStatus.InvalidURL {
        self.showMessageWithStatus(.InvalidURL)
        /*dispatch_async(self.GCDMainQueue, { () -> Void in
          self.blacklistURLTextView.text = BlackholeList.getBlacklistURL()
        })*/
      } catch {
        self.showMessageWithStatus(.UnexpectedDownloadError)
        /*dispatch_async(self.GCDMainQueue, { () -> Void in
          self.blacklistURLTextView.text = BlackholeList.getBlacklistURL()
        })*/
      }
    });
  }
  
  
  @IBAction func blockSubdomainsSwitchValueChanged(sender: AnyObject) {
    BlackholeList.setIsBlockingSubdomains(blockSubdomainsSwitch.on)
    
    SFContentBlockerManager.reloadContentBlockerWithIdentifier(
      "com.refabricants.AdScrubber.ContentBlocker", completionHandler: {
        (error: NSError?) in print("Reload complete\n")})
  }
  
  
  @IBAction func restoreDefaultSettingsTouchUpInside(sender: AnyObject) {
    BlackholeList.setDownloadedBlacklistType("none")
    refreshControls()
    reloadButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
  }
  
  
  func refreshBlockList() throws {
    
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
      }
      
      guard updateStatus == ListUpdateStatus.UpdateSuccessful else {
        return
      }
      
      do {
        let blockList = try BlackholeList.downloadBlocklist(hostsFile)
        let createBlockerListJSONResult = BlackholeList.createBlockerListJSON(blockList!)
        updateStatus = createBlockerListJSONResult.updateStatus
        if (updateStatus == .UpdateSuccessful || updateStatus == .TooManyEntries) {
          
          // if (hostsFile.absoluteString == BlackholeList.getDefaultBlacklistURL()) {
          if (hostsFile.absoluteString == BlackholeList.defaultBlacklist.getValueForKey("URL")) {
            // BlackholeList.setDefaultBlacklistEntryCount("\(createBlockerListJSONResult.numberOfEntries!)")
            BlackholeList.defaultBlacklist.setValueWithKey("\(createBlockerListJSONResult.numberOfEntries!)", forKey: "EntryCount")
            print("Updating default list: \(hostsFile.absoluteString)")
            if let etag = NSUserDefaults.standardUserDefaults().objectForKey("candidateEtag") as? String {
              // BlackholeList.setDefaultBlacklistEtag(etag)
              BlackholeList.defaultBlacklist.setValueWithKey(etag, forKey: "Etag")
              NSUserDefaults.standardUserDefaults().removeObjectForKey("candidateEtag")
            } else {
              // BlackholeList.deleteDefaultBlacklistEtag()
              BlackholeList.defaultBlacklist.removeValueForKey("Etag")
            }
          } else {
            /* BlackholeList.setCustomBlacklistFileType(createBlockerListJSONResult.blacklistFileType!)
            BlackholeList.setCustomBlacklistEntryCount("\(createBlockerListJSONResult.numberOfEntries!)")
            BlackholeList.setCustomBlacklistURL(hostsFile.absoluteString) */
            BlackholeList.customBlacklist.setValueWithKey(createBlockerListJSONResult.blacklistFileType!, forKey: "FileType")
            BlackholeList.customBlacklist.setValueWithKey("\(createBlockerListJSONResult.numberOfEntries!)", forKey: "EntryCount")
            BlackholeList.customBlacklist.setValueWithKey(hostsFile.absoluteString, forKey: "URL")
            print("setting blockerLIstURL default to: \(hostsFile.absoluteString)")
            if let etag = NSUserDefaults.standardUserDefaults().objectForKey("candidateEtag") as? String {
              // BlackholeList.setCustomBlacklistEtag(etag)
              BlackholeList.customBlacklist.setValueWithKey(etag, forKey: "Etag")
              NSUserDefaults.standardUserDefaults().removeObjectForKey("candidateEtag")
            } else {
              // BlackholeList.deleteCustomBlacklistEtag()
              BlackholeList.customBlacklist.removeValueForKey("Etag")
            }
          }
          
          
          
          
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
    
    dispatch_async(GCDMainQueue, { () -> Void in
      self.activityIndicator.stopAnimating()
      
      let alert = UIAlertController(title: "Ad Scrubber Blocklist Reload", message: status.rawValue, preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
      
    })
  }
  
  
  private func refreshControls() {
    print("\(BlackholeList.preloadedBlacklist.getValueForKey("URL"))")
    print("\(BlackholeList.preloadedBlacklist.getValueForKey("FileType"))")
    print("\(BlackholeList.preloadedBlacklist.getValueForKey("EntryCount"))")
    print("\(BlackholeList.defaultBlacklist.getValueForKey("URL"))")
    print("\(BlackholeList.defaultBlacklist.getValueForKey("FileType"))")
    print("\(BlackholeList.defaultBlacklist.getValueForKey("EntryCount"))")
    print("\(BlackholeList.customBlacklist.getValueForKey("URL"))")
    print("\(BlackholeList.customBlacklist.getValueForKey("FileType"))")
    print("\(BlackholeList.customBlacklist.getValueForKey("EntryCount"))")
    
    useCustomBlocklistSwitch.setOn(BlackholeList.getIsUseCustomBlocklistOn(), animated: true)
    if (BlackholeList.getDownloadedBlacklistType() == "custom") {
      blacklistURLTextView.text = BlackholeList.customBlacklist.getValueForKey("URL")
      typeLabel.text = BlackholeList.customBlacklist.getValueForKey("FileType")
      entryCountLabel.text = BlackholeList.customBlacklist.getValueForKey("EntryCount")
    } else if (BlackholeList.getDownloadedBlacklistType() == "default") {
      blacklistURLTextView.text = BlackholeList.defaultBlacklist.getValueForKey("URL")
      typeLabel.text = BlackholeList.defaultBlacklist.getValueForKey("FileType")
      entryCountLabel.text = BlackholeList.defaultBlacklist.getValueForKey("EntryCount")
    } else {
      blacklistURLTextView.text = BlackholeList.preloadedBlacklist.getValueForKey("URL")
      typeLabel.text = BlackholeList.preloadedBlacklist.getValueForKey("FileType")
      entryCountLabel.text = BlackholeList.preloadedBlacklist.getValueForKey("EntryCount")
    }
    
    blockSubdomainsSwitch.setOn(BlackholeList.getIsBlockingSubdomains(), animated: true)
    
    if (BlackholeList.getIsUseCustomBlocklistOn()) {
      blacklistURLTextView.textColor = UIColor.darkGrayColor()
      
      if (BlackholeList.customBlacklist.getValueForKey("FileType") == "JSON") {
        BlackholeList.setIsBlockingSubdomains(false)
        blockSubdomainsSwitch.enabled = false
        blockSubdomainsLabel.enabled = false
      } else {
        blockSubdomainsSwitch.enabled = true
        blockSubdomainsLabel.enabled = true
      }
      
    } else {
      blacklistURLTextView.textColor = UIColor.lightGrayColor()
    }
    
  }
  
  /*
  private func refreshControls() {
    useCustomBlocklistSwitch.setOn(BlackholeList.getIsUseCustomBlocklistOn(), animated: true)
    if (BlackholeList.getDownloadedBlacklistType() == "custom") {
      blacklistURLTextView.text = BlackholeList.getCustomBlacklistURL()
      typeLabel.text = BlackholeList.getCustomBlacklistFileType()
      entryCountLabel.text = BlackholeList.getCustomBlacklistEntryCount()
    } else if (BlackholeList.getDownloadedBlacklistType() == "default") {
      blacklistURLTextView.text = BlackholeList.getDefaultBlacklistURL()
      typeLabel.text = BlackholeList.getDefaultBlacklistFileType()
      entryCountLabel.text = BlackholeList.getDefaultBlacklistEntryCount()
    } else {
      blacklistURLTextView.text = BlackholeList.getDefaultBlacklistURL()
      typeLabel.text = BlackholeList.getPreloadedBlacklistFileType()
      entryCountLabel.text = BlackholeList.getDefaultBlacklistEntryCount()
    }
    
    blockSubdomainsSwitch.setOn(BlackholeList.getIsBlockingSubdomains(), animated: true)
    
    if (BlackholeList.getIsUseCustomBlocklistOn()) {
      blacklistURLTextView.textColor = UIColor.darkGrayColor()
      
      if (BlackholeList.getCustomBlacklistFileType() == "JSON") {
        BlackholeList.setIsBlockingSubdomains(false)
        blockSubdomainsSwitch.enabled = false
        blockSubdomainsLabel.enabled = false
      } else {
        blockSubdomainsSwitch.enabled = true
        blockSubdomainsLabel.enabled = true
      }
      
    } else {
      blacklistURLTextView.textColor = UIColor.lightGrayColor()
    }
    
  }*/
  
}