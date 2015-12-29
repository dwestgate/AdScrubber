//
//  BlackholeList.swift
//  Blackhole
//
//  Created by David Westgate on 12/28/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//

import Foundation
import SwiftyJSON
import SafariServices

class BLackholeList {
  /*
  enum ListUpdateStatus: ErrorType {
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
  }*/
  
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

  
  func updateBlackholeList(hostsFileURI: String) throws {
    
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
  
  
  func writeBlockerlist(jsonArray: [[String: [String: String]]]) throws -> Void {
    
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
  
}

