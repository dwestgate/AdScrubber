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
  @IBOutlet weak var detectedFileTypeLabel: UILabel!
  @IBOutlet weak var typeLabel: UILabel!
  @IBOutlet weak var entryCountLabel: UILabel!
  @IBOutlet weak var blockSmartAppBannersLabel: UILabel!
  @IBOutlet weak var blockSmartAppBannersSwitch: UISwitch!
  @IBOutlet weak var blockSubdomainSwitch: UISwitch!
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
    // refreshControls()
    /*
    useCustomBlocklistSwitch.setOn(BLackholeList.getIsUsingCustomBlocklist(), animated: true)
    blacklistURLTextView.text = BLackholeList.getBlacklistURL()
    entryCountLabel.text = BLackholeList.getBlacklistUniqueEntryCount()
    typeLabel.text = BLackholeList.getBlacklistFileType()
    blockSmartAppBannersSwitch.setOn(BLackholeList.getIsBlockingSmartAppBanners(), animated: true)
    blockSubdomainSwitch.setOn(BLackholeList.getIsBlockingSubdomains(), animated: true)*/

  }
  
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    refreshControls()
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  
  @IBAction func useCustomBlocklistSwitchValueChanged(sender: AnyObject) {
    BLackholeList.setIsUsingCustomBlocklist(self.useCustomBlocklistSwitch.on)
    if (BLackholeList.getIsUsingCustomBlocklist()) {
      blacklistURLTextView.textColor = UIColor.darkGrayColor()
      detectedFileTypeLabel.enabled = true
    } else {
      blacklistURLTextView.textColor = UIColor.lightGrayColor()
      detectedFileTypeLabel.enabled = false
    }
  }
  
  
  @IBAction func reloadButtonPressed(sender: AnyObject) {
    
    activityIndicator.startAnimating()
    
    dispatch_async(GCDUserInteractiveQueue, { () -> Void in
      
      do {
        try self.refreshBlockList()
      } catch ListUpdateStatus.NotHTTPS {
        self.showMessageWithStatus(.NotHTTPS)
        dispatch_async(self.GCDMainQueue, { () -> Void in
          self.blacklistURLTextView.text = BLackholeList.getBlacklistURL()
        })
      } catch ListUpdateStatus.InvalidURL {
        self.showMessageWithStatus(.InvalidURL)
        dispatch_async(self.GCDMainQueue, { () -> Void in
          self.blacklistURLTextView.text = BLackholeList.getBlacklistURL()
        })
      } catch {
        self.showMessageWithStatus(.UnexpectedDownloadError)
        dispatch_async(self.GCDMainQueue, { () -> Void in
          self.blacklistURLTextView.text = BLackholeList.getBlacklistURL()
        })
      }
    });
  }
  
  
  @IBAction func blockSmartAppBannersSwitchValueChanged(sender: AnyObject) {
  }
  
  
  @IBAction func aggressiveModeSwitchValueChanged(sender: AnyObject) {
    BLackholeList.setIsBlockingSubdomains(blockSubdomainSwitch.on)
    
    SFContentBlockerManager.reloadContentBlockerWithIdentifier(
      "com.refabricants.AdScrubber.ContentBlocker", completionHandler: {
        (error: NSError?) in print("Reload complete\n")})
  }
  
  
  @IBAction func restoreDefaultSettingsTouchUpInside(sender: AnyObject) {
    BLackholeList.setBlacklistURL("https://raw.githubusercontent.com/dwestgate/hosts/master/hosts")
    BLackholeList.setBlacklistUniqueEntryCount("26798")
    BLackholeList.setBlacklistFileType("hosts")
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
    
    BLackholeList.validateURL(hostsFile, completion: { (var updateStatus) -> () in
      defer {
        self.refreshControls()
        self.showMessageWithStatus(updateStatus)
      }
      
      guard updateStatus == ListUpdateStatus.UpdateSuccessful else {
        return
      }
      
      do {
        let blockList = try BLackholeList.downloadBlocklist(hostsFile)
        let createBlockerListJSONResult = BLackholeList.createBlockerListJSON(blockList!)
        updateStatus = createBlockerListJSONResult.updateStatus
        if (updateStatus == .UpdateSuccessful || updateStatus == .TooManyEntries) {
          
          BLackholeList.setBlacklistFileType(createBlockerListJSONResult.blacklistFileType!)
          BLackholeList.setBlacklistUniqueEntryCount("\(createBlockerListJSONResult.numberOfEntries!)")
          BLackholeList.setBlacklistURL(hostsFile.absoluteString)
          print("setting blockerLIstURL default to: \(hostsFile.absoluteString)")
          if let etag = NSUserDefaults.standardUserDefaults().objectForKey("candidateEtag") as? String {
            BLackholeList.setBlacklistEtag(etag)
            NSUserDefaults.standardUserDefaults().removeObjectForKey("candidateEtag")
          } else {
            BLackholeList.deleteBlacklistEtag()
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
    useCustomBlocklistSwitch.setOn(BLackholeList.getIsUsingCustomBlocklist(), animated: true)
    blacklistURLTextView.text = BLackholeList.getBlacklistURL()
    typeLabel.text = BLackholeList.getBlacklistFileType()
    entryCountLabel.text = BLackholeList.getBlacklistUniqueEntryCount()
    blockSubdomainSwitch.setOn(BLackholeList.getIsBlockingSubdomains(), animated: true)
    
    if (BLackholeList.getIsUsingCustomBlocklist()) {
      blacklistURLTextView.textColor = UIColor.darkGrayColor()
      detectedFileTypeLabel.enabled = true
    } else {
      blacklistURLTextView.textColor = UIColor.lightGrayColor()
      detectedFileTypeLabel.enabled = false
    }
    
    if (BLackholeList.getBlacklistFileType() == "hosts") {
      blockSubdomainSwitch.enabled = true
    } else {
      BLackholeList.setIsBlockingSubdomains(false)
      blockSubdomainSwitch.enabled = false
    }
    
  }
  
}