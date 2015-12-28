//
//  ViewController.swift
//  Blackhole
//
//  Created by David Westgate on 11/23/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//
// Love this! https://gist.github.com/damianesteban/c42eff0496e34d31a410

import SwiftyJSON
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
  
  private enum ListUpdateStatus: ErrorType {
    case UpdateSuccessful
    case NoUpdateRequired
    case NotHTTPS
    case InvalidURL
    case ServerNotFound
    case NoSuchFile
    case UpdateRequired
    case ErrorDownloading
    case ErrorDownloadingFromRemoteLocation
    case ErrorSavingToLocalFilesystem
    case ErrorParsingFile
    case UnableToReplaceExistingBlockerlist
    case ErrorSavingParsedFile
  }
  
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
  
  // private var updateStatus = ListUpdateStatus.UpdateSuccessful
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
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
        let blockList = try self.downloadBlocklist(hostsFile)
        let jsonArray = self.convertHostsToJSON(blockList!) as [[String: [String: String]]]?
        try self.writeBlockerlist(jsonArray!)
      } catch {
        print("Error downloading file from \(hostsFile.description)")
        return
      }
      SFContentBlockerManager.reloadContentBlockerWithIdentifier("com.refabricants.Blackhole.ContentBlocker", completionHandler: {
        (error: NSError?) in print("Reload complete\n")})
    })
    
  }
  
  
  private func validateURL(hostsFile:NSURL, completion:((urlStatus: ListUpdateStatus) -> ())?) {
    
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
  
  func downloadBlocklist(hostsFile: NSURL) throws -> NSURL? {
    
    let documentDirectory =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
    let localFile = documentDirectory.URLByAppendingPathComponent(hostsFile.lastPathComponent!)
    print(localFile)
    
    guard let myHostsFileFromUrl = NSData(contentsOfURL: hostsFile) else {
      throw ListUpdateStatus.ErrorDownloadingFromRemoteLocation
    }
    guard myHostsFileFromUrl.writeToURL(localFile, atomically: true) else {
      throw ListUpdateStatus.ErrorSavingToLocalFilesystem
    }
    print("File saved")
    return localFile
  }
  
  func convertHostsToJSON(blockList: NSURL) -> [[String: [String: String]]] {
    let validFirstChars = "01234567890abcdef"
    var jsonSet = [[String: [String: String]]]()
    
    if let sr = StreamReader(path: blockList.path!) {
      
      defer {
        sr.close()
      }
      
      while let line = sr.nextLine() {
        
        if ((!line.isEmpty) && (validFirstChars.containsString(String(line.characters.first!)))) {
          
          var uncommentedText = line
          
          if let commentPosition = line.characters.indexOf("#") {
            uncommentedText = line[line.startIndex.advancedBy(0)...commentPosition.predecessor()]
          }
          
          let lineAsArray = uncommentedText.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
          let listOfDomainsFromLine = lineAsArray.filter { $0 != "" }
          
          for domain in Array(listOfDomainsFromLine[1..<listOfDomainsFromLine.count]) {
            
            guard let validated = NSURL(string: "http://" + domain) else { break }
            guard let validatedHost = validated.host else { break }
            var components = validatedHost.componentsSeparatedByString(".")
            guard components[0].lowercaseString != "localhost" else { break }
            
            var urlFilter: String
            if ((components.count > 2) && (components[0].rangeOfString("www?\\d{0,3}", options: .RegularExpressionSearch) != nil)) {
              components[0] = ".*"
              urlFilter = components.joinWithSeparator("\\.")
            } else {
              urlFilter = ".*\\." + components.joinWithSeparator("\\.")
            }
            jsonSet.append(["action": ["type": "block"], "trigger": ["url-filter":urlFilter]])
          }
        }
      }
    }
    let valid = NSJSONSerialization.isValidJSONObject(jsonSet)
    print("JSON file is confirmed valid: \(valid). Number of elements = \(jsonSet.count)")
    
    return jsonSet
  }
  
  
  private func writeBlockerlist(jsonArray: [[String: [String: String]]]) throws -> Void {
    
    let jsonPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.refabricants.blackhole")! as NSURL
    let destinationUrl = jsonPath.URLByAppendingPathComponent("blockerList.json")
    print(destinationUrl)
    
    let json = JSON(jsonArray)
    do {
      try NSFileManager.defaultManager().removeItemAtPath(destinationUrl.path!)
      try json.description.writeToFile(destinationUrl.path!, atomically: false, encoding: NSUTF8StringEncoding)
    } catch {
      throw ListUpdateStatus.UnableToReplaceExistingBlockerlist
    }
  }
  
  private func showStatusMessage(status: ListUpdateStatus) {
    
    dispatch_async(GCDMainQueue, { () -> Void in
      self.activityIndicator.stopAnimating()
      
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

