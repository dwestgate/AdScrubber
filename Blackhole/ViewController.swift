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
  
  private enum UpdateBlackholeListStatus: Int {
    case UpdateSuccessful,
    NoUpdateRequired,
    NotHTTPS,
    InvalidURL,
    ServerNotFound,
    NoSuchFile,
    UpdateRequired,
    ErrorDownloading,
    ErrorParsingFile,
    ErrorSavingParsedFile
  }
  
  private var updateListStatus = UpdateBlackholeListStatus.UpdateSuccessful
  
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      self.refreshBlockList()
    });
  }
  
  func refreshBlockList() {
    
    guard hostsFileURI.text.lowercaseString.hasPrefix("https://") else {
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.activityIndicator.stopAnimating()
        self.updateListStatus = .NotHTTPS
        self.showStatusMessage(self.updateListStatus)
      })
      return
    }
    
    guard let hostsFile = NSURL(string: hostsFileURI.text) else {
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.activityIndicator.stopAnimating()
        self.updateListStatus = .InvalidURL
        self.showStatusMessage(self.updateListStatus)
      })
      return
    }
    
    self.checkShouldDownloadFileAtLocation(hostsFileURI.text, completion: { (shouldDownload) -> () in
      defer {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          self.activityIndicator.stopAnimating()
          self.showStatusMessage(self.updateListStatus)
        })
      }
      
      guard shouldDownload == .UpdateRequired else {
        self.updateListStatus = shouldDownload
        self.showStatusMessage(self.updateListStatus)
        return
      }
      print("Downloading file")
      
      // Create the JSON
      if let blockList = self.downloadBlocklist(hostsFile) {
        print("File downloaded successfully")
        if self.convertHostsToJSON(blockList) {
          print("File converted to JSON successfully")
        } else {
          print("Error converting file to JSON")
        }
      } else {
        print("Error downloading file from \(hostsFile.description)")
      }
      
    })
  }
  
  
  private func checkShouldDownloadFileAtLocation(urlString:String, completion:((shouldDownload:UpdateBlackholeListStatus) -> ())?) {
    
    let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
    request.HTTPMethod = "HEAD"
    let session = NSURLSession.sharedSession()
    let task = session.dataTaskWithRequest(request, completionHandler: { [weak self] data, response, error -> Void in
      if let strongSelf = self {
        var isModified = UpdateBlackholeListStatus.NoUpdateRequired
        
        defer {
          if completion != nil {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
              completion!(shouldDownload: isModified)
            })
          }
        }
        
        print("Response = \(response?.description)")
        guard let httpResp: NSHTTPURLResponse = response as? NSHTTPURLResponse else {
          isModified = .ServerNotFound
          return
        }
        
        guard httpResp.statusCode == 200 else {
          isModified = .NoSuchFile
          return
        }
        
        guard let etag = httpResp.allHeaderFields["Etag"] as? NSString else {
          isModified = .UpdateRequired
          return
        }
        
        let newEtag = etag
        if let currentEtag = NSUserDefaults.standardUserDefaults().objectForKey("etag") as? NSString {
          if !etag.isEqual(currentEtag) {
            isModified = .UpdateRequired
            NSUserDefaults.standardUserDefaults().setObject(newEtag, forKey: "etag")
          }
          
        } else {
          isModified = .UpdateRequired
          NSUserDefaults.standardUserDefaults().setObject(newEtag, forKey: "etag")
        }
      }
      
      })
    
    task.resume()
  }
  
  func downloadBlocklist(hostsFile: NSURL) -> NSURL? {
    
    // create your document folder url
    let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
    // your destination file url
    let destinationUrl = documentsUrl.URLByAppendingPathComponent(hostsFile.lastPathComponent!)
    print(destinationUrl)
    
    guard let myHostsFileFromUrl = NSData(contentsOfURL: hostsFile) else {
      print("Error saving file")
      updateSuccessfulLabel.text = "Error: Error downloading file"
      print("updateSuccessfulLabel.text = Error: unable to save file (cat)")
      return nil
    }
    guard myHostsFileFromUrl.writeToURL(destinationUrl, atomically: true) else {
      print("Error saving file")
      updateSuccessfulLabel.text = "Error: unable to save file"
      print("updateSuccessfulLabel.text = Error: Error downloading file (rat)")
      return nil
    }
    print("File saved")
    return destinationUrl
    
  }
  
  func convertHostsToJSON(blockList: NSURL) -> Bool {
    var jsonArray = [[String: [String: String]]]()
    
    guard let sr = StreamReader(path: blockList.path!) else {
      updateSuccessfulLabel.text = "Unable to parse file"
      print("updateSuccessfulLabel.text = Unable to parse file")
      return false
    }
      defer {
        sr.close()
      }
      
      var count = 0
      let validFirstChars = "01234567890abcdef"
      
      while let line = sr.nextLine() {
        count++
        
        if ((!line.isEmpty) && (validFirstChars.containsString(String(line.characters.first!)))) {
          
          var uncommentedText = line
          
          if let commentPosition = line.characters.indexOf("#") {
            uncommentedText = line[line.startIndex.advancedBy(0)...commentPosition.predecessor()]
          }
          
          let lineArray = uncommentedText.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
          let filteredArray = lineArray.filter { $0 != "" }
          var ipAddress = true
          
          for arrayElement in filteredArray {
            
            if ipAddress {
              ipAddress = false
            } else {
              
              guard let validated = NSURL(string: "http://" + arrayElement) else {
                print("Invalid domain name")
                break
              }
              
              guard let validatedHost = validated.host else {
                print("Invalid host name")
                break
              }
              
              var components = validatedHost.componentsSeparatedByString(".")
              
              guard components[0].caseInsensitiveCompare("localhost") != NSComparisonResult.OrderedSame else {
                print("Entry for localhost not being added to list")
                break
              }
              
              var domain: String
              if ((components.count > 2) && (components[0].rangeOfString("www?\\d{0,3}", options: .RegularExpressionSearch) != nil)) {
                components[0] = ".*"
                domain = components.joinWithSeparator("\\.")
              } else {
                domain = ".*\\." + components.joinWithSeparator("\\.")
              }
              jsonArray.append(["action": ["type": "block"], "trigger": ["url-filter":domain]])
            }
          }
        }
      }
    // }
    
    let valid = NSJSONSerialization.isValidJSONObject(jsonArray)
    print("JSON file is confirmed valid: \(valid)")
    
    // Write the new JSON file
    let jsonPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.refabricants.blackhole")! as NSURL
    let destinationUrl = jsonPath.URLByAppendingPathComponent("blockerList.json")
    print(destinationUrl)
    // check if it exists
    if NSFileManager().fileExistsAtPath(destinationUrl.path!) {
      print("The file already exists at path - deleting")
      do {
        try NSFileManager.defaultManager().removeItemAtPath(destinationUrl.path!)
      } catch {
        print("No file to delete")
      }
    }
    
    let json = JSON(jsonArray)
    do {
      try json.description.writeToFile(destinationUrl.path!, atomically: false, encoding: NSUTF8StringEncoding)
      print("JSON file written succesfully\n")
      SFContentBlockerManager.reloadContentBlockerWithIdentifier("com.refabricants.Blackhole.ContentBlocker", completionHandler: {
        (error: NSError?) in print("Reload complete\n")})
    } catch {
      print("Unable to write parsed file")
      updateSuccessfulLabel.text = "Unable to write parsed file"
      print("updateSuccessfulLabel.text = Unable to write parsed file (jimmy)")
    }
    if updateSuccessfulLabel.text != "Unable to write parsed file" {
      return true
    } else {
      return false
    }
  }
  
  private func showStatusMessage(status: UpdateBlackholeListStatus) {
    switch status {
    case .UpdateSuccessful: updateSuccessfulLabel.hidden = false
    case .NoUpdateRequired: noUpdateRequiredLabel.hidden = false
    case .NotHTTPS: notHTTPSLabel.hidden = false
    case .InvalidURL: invalidURLLabel.hidden = false
    case .ServerNotFound: serverNotFoundLabel.hidden = false
    case .NoSuchFile: noSuchFileLabel.hidden = false
    case .UpdateRequired: updateRequiredLabel.hidden = false
    case .ErrorDownloading: errorDownloadingLabel.hidden = false
    case .ErrorParsingFile: errorParsingFileLabel.hidden = false
    case .ErrorSavingParsedFile: errorSavingParsedFileLabel.hidden = false
    }
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
  
  //TODO: Defaults are stored properly (in defaults)!
  //TODO: Potential fails: hosts file empty; can't write; error creating json; error reading
  //TODO: Every time app runs or reload button is clicked it attempts to load default list
  //TODO: If it fails, log message and use the built-in list
  //TODO: Make sure keyboard doesn't block reload button
}

