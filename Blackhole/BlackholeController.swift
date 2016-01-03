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
    
    if let blockerListURL = NSUserDefaults.standardUserDefaults().objectForKey("blockerListURL") as? String {
      hostsFileURI.text = blockerListURL
      print("\n\nDefault value being used to populate textView = \(blockerListURL)")
    } else {
      NSUserDefaults.standardUserDefaults().setObject(hostsFileURI.text, forKey: "blockerListURL")
      print("\n\nSetting Default view to: \(hostsFileURI.text)")
    }

  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
    hostsFileURI.resignFirstResponder()
    print("\n\nwe're here\n\n")
    super.touchesBegan(touches, withEvent: event)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  @IBAction func reloadButtonPressed(sender: UIButton) {
    
    activityIndicator.startAnimating()
    
    dispatch_async(GCDUserInteractiveQueue, { () -> Void in
      
      do {
        try self.refreshBlockList()
      } catch ListUpdateStatus.NotHTTPS {
        self.showStatusMessage(.NotHTTPS)
      } catch ListUpdateStatus.InvalidURL {
        self.showStatusMessage(.InvalidURL)
      } catch {
        self.showStatusMessage(.UnexpectedDownloadError)
      }
      dispatch_async(self.GCDMainQueue, { () -> Void in
        self.hostsFileURI.text = NSUserDefaults.standardUserDefaults().objectForKey("blockerListURL") as? String
      })
      
    });
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
        if (urlStatus == .UpdateSuccessful) {
          NSUserDefaults.standardUserDefaults().setObject(hostsFile.absoluteString, forKey: "blockerListURL")
        }
        self.showStatusMessage(urlStatus)
      }
      
      guard urlStatus == ListUpdateStatus.UpdateSuccessful else {
        return
      }
      
      do {
        let blockList = try BLackholeList.downloadBlocklist(hostsFile)
        
        let jsonArrays = BLackholeList.createBlockerListJSON(blockList!) as ([[String: [String: String]]], [[String: [String: String]]])?

        try BLackholeList.writeBlockerlist("blockerList.json", jsonArray: jsonArrays!.0)
        
        // If we have just loaded a JSON file, jsonArray!.1, so we will
        // update the interface accordingly
        if (jsonArrays!.1.count > 0) {
          try BLackholeList.writeBlockerlist("wildcardBlockerList.json", jsonArray: jsonArrays!.1)
          self.changeFileType("hosts")
        } else {
          try BLackholeList.writeBlockerlist("wildcardBlockerList.json", jsonArray: jsonArrays!.0)
          self.changeFileType("JSON")
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
  
  /*
  func validateURL(hostsFile:NSURL, completion:((urlStatus: ListUpdateStatus) -> ())?) {
    
    let request = NSMutableURLRequest(URL: hostsFile)
    request.HTTPMethod = "HEAD"
    let session = NSURLSession.sharedSession()
    
    let task = session.dataTaskWithRequest(request, completionHandler: { [weak self] data, response, error -> Void in
      if let strongSelf = self {
        var result = ListUpdateStatus.UpdateSuccessful
        
        defer {
          if completion != nil {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
              completion!(urlStatus: result)
            })
          }
        }
        
        print("Response = \(response?.description)")
        guard let httpResp: NSHTTPURLResponse = response as? NSHTTPURLResponse else {
          result = ListUpdateStatus.ServerNotFound
          return
        }
        
        guard httpResp.statusCode == 200 else {
          result = ListUpdateStatus.NoSuchFile
          return
        }
        
        if let remoteEtag = httpResp.allHeaderFields["Etag"] as? NSString,
          currentEtag = NSUserDefaults.standardUserDefaults().objectForKey("etag") as? NSString {
            if remoteEtag.isEqual(currentEtag) {
              result = ListUpdateStatus.NoUpdateRequired
            } else {
              NSUserDefaults.standardUserDefaults().setObject(remoteEtag, forKey: "etag")
            }
        }
      }
      })
    
    task.resume()
  }*/
  
  
  private func showStatusMessage(status: ListUpdateStatus) {
    
    dispatch_async(GCDMainQueue, { () -> Void in
      self.activityIndicator.stopAnimating()
      
      let alert = UIAlertController(title: "Blackhole List Reload", message: status.rawValue, preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
      
    })
  }
  
  private func changeFileType(type: String) {
    if type == "hosts" {
      self.blockSubdomainSwitch.enabled = true
      self.typeLabel.text = "hosts"
    } else {
      self.blockSubdomainSwitch.setOn(false, animated: true)
      self.blockSubdomainSwitch.enabled = false
      self.typeLabel.text = "JSON"
    }
  }
  
}