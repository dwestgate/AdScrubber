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
    
    hostsFileURI.text = BLackholeList.getBlockerListURL()
    entryCountLabel.text = BLackholeList.getEntryCount()
    typeLabel.text = BLackholeList.getFileType()
    blockSubdomainSwitch.setOn(BLackholeList.getBlockingSubdomains(), animated: true)
    
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
    hostsFileURI.resignFirstResponder()
    print("\n\nwe're here\n\n")
    super.touchesBegan(touches, withEvent: event)
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
        self.showStatusMessage(.NotHTTPS)
        dispatch_async(self.GCDMainQueue, { () -> Void in
          self.hostsFileURI.text = BLackholeList.getBlockerListURL()
        })
      } catch ListUpdateStatus.InvalidURL {
        self.showStatusMessage(.InvalidURL)
        dispatch_async(self.GCDMainQueue, { () -> Void in
          self.hostsFileURI.text = BLackholeList.getBlockerListURL()
        })
      } catch {
        self.showStatusMessage(.UnexpectedDownloadError)
        dispatch_async(self.GCDMainQueue, { () -> Void in
          self.hostsFileURI.text = BLackholeList.getBlockerListURL()
        })
      }
    });
  }
  
  
  @IBAction func blockingSubdomainsSwitch(sender: AnyObject) {
    BLackholeList.setBlockingSubdomains(self.blockSubdomainSwitch.on)
    self.hostsFileURI.text = BLackholeList.getBlockerListURL()
    
    SFContentBlockerManager.reloadContentBlockerWithIdentifier(
      "com.refabricants.Blackhole.ContentBlocker", completionHandler: {
      (error: NSError?) in print("Reload complete\n")})
  }
  
  
  @IBAction func restoreDefaultSettingsTouchUpInside(sender: AnyObject) {
    BLackholeList.setBlockerListURL("https://raw.githubusercontent.com/dwestgate/hosts/master/hosts")
    BLackholeList.setEntryCount("26798")
    BLackholeList.setFileType("hosts")
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
    
    BLackholeList.validateURL(hostsFile, completion: { (var urlStatus) -> () in
      defer {
        self.refreshControls()
        self.showStatusMessage(urlStatus)
      }
      
      guard urlStatus == ListUpdateStatus.UpdateSuccessful else {
        return
      }
      
      do {
        let blockList = try BLackholeList.downloadBlocklist(hostsFile)
        
        // We'll get back two arrays: if starting with a hosts file, the second file will have
        // wildcards. If starting with a JSON file, the arrays will be identical.
        let jsonArrays = BLackholeList.createBlockerListJSON(blockList!) as ([[String: [String: String]]], [[String: [String: String]]])?
        
        try BLackholeList.writeBlockerlist("blockerList.json", jsonArray: jsonArrays!.0)
        
        // If we have just loaded a JSON file, jsonArray!.1, so we will
        // update the interface accordingly
        if (jsonArrays!.1.count > 0) {
          try BLackholeList.writeBlockerlist("wildcardBlockerList.json", jsonArray: jsonArrays!.1)
          BLackholeList.setFileType("hosts")
          // self.changeFileType("hosts")
        } else {
          try BLackholeList.writeBlockerlist("wildcardBlockerList.json", jsonArray: jsonArrays!.0)
          BLackholeList.setFileType("JSON")
        }
        
        let uniqueEntries = "\(jsonArrays!.0.count)"
        
        BLackholeList.setEntryCount(uniqueEntries)
        BLackholeList.setBlockerListURL(hostsFile.absoluteString)
        print("setting blockerLIstURL default to: \(hostsFile.absoluteString)")
        if let etag = NSUserDefaults.standardUserDefaults().objectForKey("candidateEtag") as? String {
          BLackholeList.setEtag(etag)
          NSUserDefaults.standardUserDefaults().removeObjectForKey("candidateEtag")
        } else {
          BLackholeList.deleteEtag()
        }
        
      } catch {
        if urlStatus == .UpdateSuccessful {
          urlStatus = ListUpdateStatus.UnableToReplaceExistingBlockerlist
        }
        return
      }
      
      SFContentBlockerManager.reloadContentBlockerWithIdentifier("com.refabricants.Blackhole.ContentBlocker", completionHandler: {
        (error: NSError?) in print("Reload complete\n")})
    })
    
  }
  
  
  private func showStatusMessage(status: ListUpdateStatus) {
    
    dispatch_async(GCDMainQueue, { () -> Void in
      self.activityIndicator.stopAnimating()
      
      let alert = UIAlertController(title: "Blackhole List Reload", message: status.rawValue, preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
      
    })
  }
  
  
  private func refreshControls() {
      self.hostsFileURI.text = BLackholeList.getBlockerListURL()
      self.typeLabel.text = BLackholeList.getFileType()
      self.entryCountLabel.text = BLackholeList.getEntryCount()
      if (BLackholeList.getFileType() == "hosts") {
        self.blockSubdomainSwitch.enabled = true
      } else {
        BLackholeList.setBlockingSubdomains(false)
        self.blockSubdomainSwitch.enabled = false
      }
      self.blockSubdomainSwitch.setOn(BLackholeList.getBlockingSubdomains(), animated: true)
  }
  
}