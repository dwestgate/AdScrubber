//
//  BlackholeController.swift
//  Blackhole
//
//  Created by David Westgate on 12/31/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

class BlackholeController: UITableViewController {
  
  
  @IBOutlet weak var hostsFileURI: UITextView!
  @IBOutlet weak var typeLabel: UILabel!
  @IBOutlet weak var entryCountLabel: UILabel!
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
    
    hostsFileURI.text = BLackholeList.getBlacklistURL()
    entryCountLabel.text = BLackholeList.getBlacklistUniqueEntryCount()
    typeLabel.text = BLackholeList.getBlacklistFileType()
    blockSubdomainSwitch.setOn(BLackholeList.getIsBlockingSubdomains(), animated: true)
    
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "endEditing"))
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  
  @IBAction func reloadButtonPressed(sender: AnyObject) {
    
    activityIndicator.startAnimating()
    
    dispatch_async(GCDUserInteractiveQueue, { () -> Void in
      
      do {
        try self.refreshBlockList()
      } catch ListUpdateStatus.NotHTTPS {
        self.showMessageWithStatus(.NotHTTPS)
        dispatch_async(self.GCDMainQueue, { () -> Void in
          self.hostsFileURI.text = BLackholeList.getBlacklistURL()
        })
      } catch ListUpdateStatus.InvalidURL {
        self.showMessageWithStatus(.InvalidURL)
        dispatch_async(self.GCDMainQueue, { () -> Void in
          self.hostsFileURI.text = BLackholeList.getBlacklistURL()
        })
      } catch {
        self.showMessageWithStatus(.UnexpectedDownloadError)
        dispatch_async(self.GCDMainQueue, { () -> Void in
          self.hostsFileURI.text = BLackholeList.getBlacklistURL()
        })
      }
    });
  }
  
  
  @IBAction func blockingSubdomainsSwitch(sender: AnyObject) {
    BLackholeList.setIsBlockingSubdomains(self.blockSubdomainSwitch.on)
    self.hostsFileURI.text = BLackholeList.getBlacklistURL()
    
    SFContentBlockerManager.reloadContentBlockerWithIdentifier(
      "com.refabricants.Blackhole.ContentBlocker", completionHandler: {
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
    
    guard hostsFileURI.text.lowercaseString.hasPrefix("https://") else {
      throw ListUpdateStatus.NotHTTPS
    }
    guard let hostsFile = NSURL(string: hostsFileURI.text) else {
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
        SFContentBlockerManager.reloadContentBlockerWithIdentifier("com.refabricants.Blackhole.ContentBlocker", completionHandler: {
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
  
  
  func endEditing() {
    view.endEditing(true)
  }
  
  
  private func showMessageWithStatus(status: ListUpdateStatus) {
    
    dispatch_async(GCDMainQueue, { () -> Void in
      self.activityIndicator.stopAnimating()
      
      let alert = UIAlertController(title: "Blackhole List Reload", message: status.rawValue, preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
      
    })
  }
  
  
  private func refreshControls() {
      self.hostsFileURI.text = BLackholeList.getBlacklistURL()
      self.typeLabel.text = BLackholeList.getBlacklistFileType()
      self.entryCountLabel.text = BLackholeList.getBlacklistUniqueEntryCount()
      if (BLackholeList.getBlacklistFileType() == "hosts") {
        self.blockSubdomainSwitch.enabled = true
      } else {
        BLackholeList.setIsBlockingSubdomains(false)
        self.blockSubdomainSwitch.enabled = false
      }
      self.blockSubdomainSwitch.setOn(BLackholeList.getIsBlockingSubdomains(), animated: true)
  }
  
}