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
  @IBOutlet weak var loadResult: UILabel!
  @IBOutlet weak var reloadButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBAction func updateHostsFileButtonPressed(sender: UIButton) {
    
    activityIndicator.startAnimating()
    loadResult.hidden = true
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      self.loadHostsFile()
    });
  }
  
  func loadHostsFile() {
    
    loadResult.text = "Blackhole list successfully loaded"
    
    if let hostsFile = NSURL(string: hostsFileURI.text) {
      // create your document folder url
      let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
      // your destination file url
      var destinationUrl = documentsUrl.URLByAppendingPathComponent(hostsFile.lastPathComponent!)
      print(destinationUrl)
      // check if it exists before downloading it
      /* if NSFileManager().fileExistsAtPath(destinationUrl.path!) {
        print("The file already exists at path")
        loadResult.text = "File already exists"
      } else { */
        //  if the file doesn't exist just download the data from your url
        if let myHostsFileFromUrl = NSData(contentsOfURL: hostsFile) {
          // after downloading your data you need to save it to your destination url
          if myHostsFileFromUrl.writeToURL(destinationUrl, atomically: true) {
            print("File saved")
          } else {
            print("Error saving file")
            loadResult.text = "Error: unable to save file"
          }
        }
      // }
      
      // Create the JSON
      if NSFileManager().fileExistsAtPath(destinationUrl.path!) {
        
        var jsonArray = [[String: [String: String]]]()
        
        if let sr = StreamReader(path: destinationUrl.path!) {
          defer {
            sr.close()
          }
          
          var count = 0
          
          while let line = sr.nextLine() {
            count++
            if (line.characters.first != "#") {
              let regex = try! NSRegularExpression(pattern: "(?:^[0-9.:]+[ \t]+)|(?:[ \t]+$)",
                options: [.CaseInsensitive])
              let range = NSMakeRange(0, line.characters.count)
              
              let urlToBlock = regex.stringByReplacingMatchesInString(line, options: NSMatchingOptions.ReportCompletion, range: range, withTemplate: "$1")
              
              if ((urlToBlock.caseInsensitiveCompare("localhost") != NSComparisonResult.OrderedSame) && (urlToBlock.characters.count != 0)) {
                
                let replaced = ".*\\." + urlToBlock.stringByReplacingOccurrencesOfString(".", withString: "\\.")
                
                jsonArray.append(["action": ["type": "block"], "trigger": ["url-filter":replaced]])
              }
            }
          }
        } else {
          loadResult.text = "Unable to parse file"
        }
        
        let valid = NSJSONSerialization.isValidJSONObject(jsonArray)
        print(valid)
        
        // Write the new JSON file
        let jsonPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.refabricants.blackhole")! as NSURL
        destinationUrl = jsonPath.URLByAppendingPathComponent("blockerList.json")
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
          loadResult.text = "Unable to write parsed file"
        }
      }
    } else {
      loadResult.text = "No file at URL provided"
    }
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.activityIndicator.stopAnimating()
      self.loadResult.hidden = false
    })
  }
  
}

