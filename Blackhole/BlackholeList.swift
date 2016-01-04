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
  
  static let container = NSUserDefaults.init(suiteName: "group.com.refabricants.blackhole")


  static func getBlockerListURL() -> String {
    if let value = container!.objectForKey("blockerListURL") as? String {
      return value
    } else {
      let value = "https://raw.githubusercontent.com/dwestgate/hosts/master/hosts"
      container!.setObject(value, forKey: "blockerListURL")
      return value
    }
  }
  
  
  static func setBlockerListURL(value: String) {
    container!.setObject(value, forKey: "blockerListURL")
  }
  
  
  static func getEntryCount() -> String {
    if let value = container!.objectForKey("entryCount") as? String {
      return value
    } else {
      let value = "26798"
      container!.setObject(value, forKey: "entryCount")
      return value
    }
  }
  
  
  static func setEntryCount(value: String) {
    container!.setObject(value, forKey: "entryCount")
  }
  
  
  static func getFileType() -> String {
    if let value = container!.objectForKey("fileType") as? String {
      return value
    } else {
      let value = "hosts"
      container!.setObject(value, forKey: "fileType")
      return value
    }
  }
  
  
  static func setFileType(value: String) {
    container!.setObject(value, forKey: "fileType")
  }
  
  
  static func getEtag() -> String? {
    if let value = container!.objectForKey("etag") as? String {
      return value
    } else {
      return nil
    }
  }
  
  
  static func setEtag(value: String) {
    container!.setObject(value, forKey: "etag")
  }
  
  
  static func deleteEtag() {
    container!.removeObjectForKey("etag")
  }
  
  
  static func getBlockingSubdomains() -> Bool {
    if let value = container!.boolForKey("blockingSubdomains") as Bool? {
      return value
    } else {
      let value = false
      container!.setBool(value, forKey: "blockingSubdomains")
      return value
    }
  }
  
  
  static func setBlockingSubdomains(value: Bool) {
    container!.setBool(value, forKey: "blockingSubdomains")
  }
  
  static func validateURL(hostsFile:NSURL, completion:((urlStatus: ListUpdateStatus) -> ())?) {
    
    let request = NSMutableURLRequest(URL: hostsFile)
    request.HTTPMethod = "HEAD"
    let session = NSURLSession.sharedSession()
    
    let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error -> Void in
      // if let strongSelf = self {
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
      
      // check to see if the remote file has an etag
      //   Yes: Do we have a default etag set?
      //     Yes: Are the two the same?
      //       Yes: ListUpdateStatus.NoUpdateRequired
      //       No:  Update the default etag and the default filename
      //     No: Update the default etag and the default filename
      //   No: Clear the default etag and update the default filename
      

      let defaults = NSUserDefaults.init(suiteName: "group.com.refabricants.blackhole")
      
      if let candidateEtag = httpResp.allHeaderFields["Etag"] as? NSString {
        if let currentEtag = defaults!.objectForKey("etag") as? NSString {
          if candidateEtag.isEqual(currentEtag) {
            result = ListUpdateStatus.NoUpdateRequired
            print("\n\nNo need to update - etags match\n\n")
          } else {
            NSUserDefaults.standardUserDefaults().setObject(candidateEtag, forKey: "candidateEtag")
            print("\n\nSetting default to \(hostsFile.absoluteString)\n\n")
          }
        } else {
          NSUserDefaults.standardUserDefaults().setObject(candidateEtag, forKey: "candidateEtag")
          print("\n\nNo existing etag - setting default to \(hostsFile.absoluteString)\n\n")
        }
      } else {
        NSUserDefaults.standardUserDefaults().removeObjectForKey("candidateEtag")
        print("\n\nDeleting etag")
      }
    })
    
    task.resume()
  }
  
  
  static func downloadBlocklist(hostsFile: NSURL) throws -> NSURL? {
    
    let documentDirectory =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
    let localFile = documentDirectory.URLByAppendingPathComponent(hostsFile.lastPathComponent!)
    print(localFile)
    
    guard let myHostsFileFromUrl = NSData(contentsOfURL: hostsFile) else {
      throw ListUpdateStatus.ErrorDownloading
    }
    guard myHostsFileFromUrl.writeToURL(localFile, atomically: true) else {
      throw ListUpdateStatus.ErrorSavingToLocalFilesystem
    }
    return localFile
  }
  
  
  static func createBlockerListJSON(blockList: NSURL) -> (noWildcards: [[String: [String: String]]], withWildcards: [[String: [String: String]]]) {
    
    var jsonSet = [[String: [String: String]]]()
    var jsonWildcardSet = [[String: [String: String]]]()
    
    let data = NSData(contentsOfURL: blockList)
    
    if let jsonArray = JSON(data: data!).arrayObject {
      if NSJSONSerialization.isValidJSONObject(jsonArray) {
        
        for element in jsonArray {
          if let newElement = element as? [String : [String : String]] {
            if ((newElement.keys.count == 2) &&
              (((areEqual("action", comparedTo: newElement.first!.0) &&
                (areEqual("trigger", comparedTo: newElement.dropFirst().first!.0)))) ||
                ((areEqual("trigger", comparedTo: newElement.first!.0) &&
                  (areEqual("action", comparedTo: newElement.dropFirst().first!.0)))))) {
                    jsonSet.append(element as! [String : [String : String]])
            } else {
              print("bad entry")
            }
          } else {
            print("Invalid element")
          }
        }
        print("\n\nThe file downloaded is valid JSON\n\n")
      }
    } else {
      if let sr = StreamReader(path: blockList.path!) {
        
        let validFirstChars = "01234567890abcdef"
        
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
              
              let urlFilter = components.joinWithSeparator("\\.")
              var wildcardURLFilter: String
              
              if ((components.count > 2) && (components[0].rangeOfString("www?\\d{0,3}", options: .RegularExpressionSearch) != nil)) {
                components[0] = ".*"
                wildcardURLFilter = components.joinWithSeparator("\\.")
              } else {
                wildcardURLFilter = ".*\\." + components.joinWithSeparator("\\.")
              }
              jsonSet.append(["action": ["type": "block"], "trigger": ["url-filter":urlFilter]])
              jsonWildcardSet.append(["action": ["type": "block"], "trigger": ["url-filter":wildcardURLFilter]])
            }
          }
        }
      }
    }
    
    let valid = NSJSONSerialization.isValidJSONObject(jsonSet)
    print("JSON file is confirmed valid: \(valid). Number of elements = \(jsonSet.count)")
    
    return (jsonSet, jsonWildcardSet)
  }
  
  
  static func writeBlockerlist(fileName: String, jsonArray: [[String: [String: String]]]) throws -> Void {
    
    let jsonPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.refabricants.blackhole")! as NSURL
    let destinationUrl = jsonPath.URLByAppendingPathComponent(fileName)
    print(destinationUrl)
    
    let json = JSON(jsonArray)
    
    _ = try? NSFileManager.defaultManager().removeItemAtPath(destinationUrl.path!)
    
    do {
      try json.description.writeToFile(destinationUrl.path!, atomically: false, encoding: NSUTF8StringEncoding)
    } catch {
      throw ListUpdateStatus.UnableToReplaceExistingBlockerlist
    }
  }
  
  static func areEqual(text: String, comparedTo: String) -> Bool {
    if (text.caseInsensitiveCompare(comparedTo) == NSComparisonResult.OrderedSame) {
      return true
    } else {
      return false
    }
  }
  
}

