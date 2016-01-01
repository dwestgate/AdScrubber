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
  @IBOutlet weak var resetButton: UIButton!
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
    
    self.title = "Blackhole"
    
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
    hostsFileURI.resignFirstResponder()
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
        self.showStatusMessage(urlStatus)
      }
      
      guard urlStatus == ListUpdateStatus.UpdateSuccessful else {
        return
      }
      
      do {
        let bhl = BLackholeList()
        let blockList = try bhl.downloadBlocklist(hostsFile)
        let jsonArray = bhl.convertHostsToJSON(blockList!) as [[String: [String: String]]]?
        try bhl.writeBlockerlist(jsonArray!)
      } catch {
        urlStatus = ListUpdateStatus.ErrorDownloading
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
  
}