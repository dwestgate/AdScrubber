//
//  ViewController.swift
//  Blackhole
//
//  Created by David Westgate on 11/23/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//

import SwiftyJSON
import UIKit
import SafariServices

class ViewController: UIViewController {
  
  @IBOutlet weak var hostsFileURI: UITextView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  @IBOutlet weak var mustBeHTTPSLabel: UILabel!
  
  @IBOutlet weak var blackholeListUpdatedLabel: UILabel!
  
  @IBOutlet weak var reloadButton: UIButton!
  
  enum Status: Int {
    case success, failure
  }
  
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
    
    blackholeListUpdatedLabel.text = "Blackhole list successfully loaded"
    
    guard let hostsFile = NSURL(string: hostsFileURI.text) else {
      blackholeListUpdatedLabel.text = "No file at URL provided"
      print("blackholeListUpdatedLabel.text = No file at URL provided")
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.activityIndicator.stopAnimating()
        print("self.activityIndicator.stopAnimating (B)")
        self.blackholeListUpdatedLabel.hidden = false
        print("blackholeListUpdatedLabel.hidden = false (B)")
      })
      return
    }
    
    self.checkShouldDownloadFileAtLocation(hostsFileURI.text, completion: { (shouldDownload) -> () in
      if shouldDownload {
        
        defer {
          
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
        
      } else {
        print("File is up-to-date")
        self.blackholeListUpdatedLabel.text = "No updates to download"
        print("blackholeListUpdatedLabel.text = No updates to download")
      }
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.activityIndicator.stopAnimating()
        self.blackholeListUpdatedLabel.hidden = false
      })
      
    })
    
  }
  
  
  func checkShouldDownloadFileAtLocation(urlString:String, completion:((shouldDownload:Bool) -> ())?) {
    let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
    request.HTTPMethod = "HEAD"
    let session = NSURLSession.sharedSession()
    
    let task = session.dataTaskWithRequest(request, completionHandler: { [weak self] data, response, error -> Void in
      if let strongSelf = self {
        var isModified = false
        print("Response = \(response?.description)")
        if let httpResp: NSHTTPURLResponse = response as? NSHTTPURLResponse {
          
          if let etag = httpResp.allHeaderFields["Etag"] as? NSString {
            let newEtag = etag
            print("\netag = \(etag)\n")
            print("newEtag = \(newEtag)\n")
            if let currentEtag = NSUserDefaults.standardUserDefaults().objectForKey("etag") as? NSString {
              print("currentEtag = \(currentEtag)\n\n")
              if !etag.isEqual(currentEtag) {
                isModified = true
                NSUserDefaults.standardUserDefaults().setObject(newEtag, forKey: "etag")
              }
              
            } else {
              isModified = true
              NSUserDefaults.standardUserDefaults().setObject(newEtag, forKey: "etag")
            }
          } else {
            isModified = true
          }
        }
        
        if completion != nil {
          dispatch_async(dispatch_get_main_queue(), { () -> Void in
            completion!(shouldDownload: isModified)
          })
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
      blackholeListUpdatedLabel.text = "Error: Error downloading file"
      print("blackholeListUpdatedLabel.text = Error: unable to save file (cat)")
      return nil
    }
    guard myHostsFileFromUrl.writeToURL(destinationUrl, atomically: true) else {
      print("Error saving file")
      blackholeListUpdatedLabel.text = "Error: unable to save file"
      print("blackholeListUpdatedLabel.text = Error: Error downloading file (rat)")
      return nil
    }
    print("File saved")
    return destinationUrl
    
  }
  
  func convertHostsToJSON(blockList: NSURL) -> Bool {
    var jsonArray = [[String: [String: String]]]()
    
    if let sr = StreamReader(path: blockList.path!) {
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
    } else {
      blackholeListUpdatedLabel.text = "Unable to parse file"
      print("blackholeListUpdatedLabel.text = Unable to parse file")
    }
    
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
      blackholeListUpdatedLabel.text = "Unable to write parsed file"
      print("blackholeListUpdatedLabel.text = Unable to write parsed file (jimmy)")
    }
    if blackholeListUpdatedLabel.text != "Unable to write parsed file" {
      return true
    } else {
      return false
    }
  }
  
  func showStatusMessage(status: Status) {
    switch status {
    case .success: blackholeListUpdatedLabel.hidden = false
    case .failure: mustBeHTTPSLabel.hidden = false
    }
  }
  
  func hideStatusMessages() {
    mustBeHTTPSLabel.hidden = true
    blackholeListUpdatedLabel.hidden = true
  }
  
  //TODO: Defaults are stored properly (in defaults)!
  //TODO: Potential fails: hosts file empty; can't write; error creating json; error reading
  //TODO: Every time app runs or reload button is clicked it attempts to load default list
  //TODO: If it fails, log message and use the built-in list
  //TODO: Make sure keyboard doesn't block reload button
}

