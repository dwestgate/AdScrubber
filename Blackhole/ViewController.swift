//
//  ViewController.swift
//  Blackhole
//
//  Created by David Westgate on 11/23/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//
/*
import UIKit
import SafariServices

class ViewController: UIViewController {
  
  @IBOutlet weak var hostsFileURI: UITextView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  @IBOutlet weak var updateSuccessfulLabel: UILabel!
  @IBOutlet weak var noUpdateRequiredLabel: UILabel!
  @IBOutlet weak var notHTTPSLabel: UILabel!
  @IBOutlet weak var invalidURLLabel: UILabel!
  @IBOutlet weak var serverNotFoundLabel: UILabel!
  @IBOutlet weak var noSuchFileLabel: UILabel!
  @IBOutlet weak var updateRequiredLabel: UILabel!
  @IBOutlet weak var errorDownloadingLabel: UILabel!
  @IBOutlet weak var errorParsingFileLabel: UILabel!
  @IBOutlet weak var errorSavingParsedFileLabel: UILabel!
  
  @IBOutlet weak var reloadButton: UIButton!
  
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
    
    hostsFileURI.layer.borderWidth = 5.0
    hostsFileURI.layer.borderWidth = 1.0
    hostsFileURI.layer.cornerRadius = 5.0
    hostsFileURI.layer.borderColor = UIColor.grayColor().CGColor
    
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
    hostsFileURI.resignFirstResponder()
    super.touchesBegan(touches, withEvent: event)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  @IBAction func updateHostsFileButtonPressed(sender: UIButton) {
    
    activityIndicator.startAnimating()
    hideStatusMessages()
    
    dispatch_async(GCDUserInteractiveQueue, { () -> Void in
      
      do {
        try self.refreshBlockList()
      } catch ListUpdateStatus.NotHTTPS {
        self.showStatusMessage(.NotHTTPS)
      } catch ListUpdateStatus.InvalidURL {
        self.showStatusMessage(.InvalidURL)
      } catch {
        print("that worked")
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
    
    self.validateURL(hostsFile, completion: { (urlStatus) -> () in
      defer {
        self.showStatusMessage(urlStatus)
      }
      
      guard urlStatus == ListUpdateStatus.UpdateSuccessful else {
        return
      }
      
      do {
        let blockList = try BLackholeList.downloadBlocklist(hostsFile)
        let jsonArray = BLackholeList.createBlockerListJSON(blockList!) as [[String: [String: String]]]?
        try BLackholeList.writeBlockerlist(jsonArray!)
      } catch {
        print("Error downloading file from \(hostsFile.description)")
        // result = ListUpdateStatus.ErrorDownloadingFromRemoteLocation
        return
      }
      SFContentBlockerManager.reloadContentBlockerWithIdentifier("com.refabricants.Blackhole.ContentBlocker", completionHandler: {
        (error: NSError?) in print("Reload complete\n")})
    })
    
  }
  
  
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
  }
  
  
  private func showStatusMessage(status: ListUpdateStatus) {
    
    dispatch_async(GCDMainQueue, { () -> Void in
      self.activityIndicator.stopAnimating()
      
      let alert = UIAlertController(title: "Blackhole List Reload", message: status.rawValue, preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
      
      switch status {
      case .UpdateSuccessful: self.updateSuccessfulLabel.hidden = false
      case .NoUpdateRequired: self.noUpdateRequiredLabel.hidden = false
      case .NotHTTPS: self.notHTTPSLabel.hidden = false
      case .InvalidURL: self.invalidURLLabel.hidden = false
      case .ServerNotFound: self.serverNotFoundLabel.hidden = false
      case .NoSuchFile: self.noSuchFileLabel.hidden = false
      case .UpdateRequired: self.updateRequiredLabel.hidden = false
      case .ErrorDownloading: self.errorDownloadingLabel.hidden = false
      case .ErrorParsingFile: self.errorParsingFileLabel.hidden = false
      case .ErrorSavingParsedFile: self.errorSavingParsedFileLabel.hidden = false
      default:
        print("Default")
      }
      
    })
  }
  
  private func hideStatusMessages() {
    updateSuccessfulLabel.hidden = true
    noUpdateRequiredLabel.hidden = true
    notHTTPSLabel.hidden = true
    invalidURLLabel.hidden = true
    serverNotFoundLabel.hidden = true
    noSuchFileLabel.hidden = true
    updateRequiredLabel.hidden = true
    errorDownloadingLabel.hidden = true
    errorParsingFileLabel.hidden = true
    errorSavingParsedFileLabel.hidden = true
  }
  
}
*/
