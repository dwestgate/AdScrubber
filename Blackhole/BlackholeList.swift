//
//  BlackholeList.swift
//  Blackhole
//
//  Created by David Westgate on 12/28/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//
//  TODO - Animation stops when resuming
//  TODO - Change name of "Blocking Subdomains"

import Foundation
import SwiftyJSON
import SafariServices

struct BLackholeList {
  
  static let sharedContainer = NSUserDefaults.init(suiteName: "group.com.refabricants.blackhole")
  
  
  static func getBlacklistURL() -> String {
    if let value = sharedContainer!.objectForKey("blacklistURL") as? String {
      return value
    } else {
      let value = "https://raw.githubusercontent.com/dwestgate/hosts/master/hosts"
      sharedContainer!.setObject(value, forKey: "blacklistURL")
      return value
    }
  }
  
  
  static func setBlacklistURL(value: String) {
    sharedContainer!.setObject(value, forKey: "blacklistURL")
  }
  
  
  static func getBlacklistUniqueEntryCount() -> String {
    if let value = sharedContainer!.objectForKey("blacklistUniqueEntryCount") as? String {
      return value
    } else {
      let value = "26798"
      sharedContainer!.setObject(value, forKey: "blacklistUniqueEntryCount")
      return value
    }
  }
  
  
  static func setBlacklistUniqueEntryCount(value: String) {
    sharedContainer!.setObject(value, forKey: "blacklistUniqueEntryCount")
  }
  
  
  static func getBlacklistFileType() -> String {
    if let value = sharedContainer!.objectForKey("blacklistFileType") as? String {
      return value
    } else {
      let value = "hosts"
      sharedContainer!.setObject(value, forKey: "blacklistFileType")
      return value
    }
  }
  
  
  static func setBlacklistFileType(value: String) {
    sharedContainer!.setObject(value, forKey: "blacklistFileType")
  }
  
  
  static func getBlacklistEtag() -> String? {
    if let value = sharedContainer!.objectForKey("blacklistEtag") as? String {
      return value
    } else {
      return nil
    }
  }
  
  
  static func setBlacklistEtag(value: String) {
    sharedContainer!.setObject(value, forKey: "blacklistEtag")
  }
  
  
  static func deleteBlacklistEtag() {
    sharedContainer!.removeObjectForKey("blacklistEtag")
  }
  
  
  static func getIsReloading() -> Bool {
    if let value = sharedContainer!.boolForKey("isReloading") as Bool? {
      return value
    } else {
      let value = false
      sharedContainer!.setBool(value, forKey: "isReloading")
      return value
    }
  }
  
  
  static func setIsReloading(value: Bool) {
      sharedContainer!.setBool(value, forKey: "isReloading")
  }
  
  
  static func getIsBlockingSubdomains() -> Bool {
    if let value = sharedContainer!.boolForKey("isBlockingSubdomains") as Bool? {
      return value
    } else {
      let value = false
      sharedContainer!.setBool(value, forKey: "isBlockingSubdomains")
      return value
    }
  }
  
  
  static func setIsBlockingSubdomains(value: Bool) {
    sharedContainer!.setBool(value, forKey: "isBlockingSubdomains")
  }
  
  static func validateURL(hostsFile:NSURL, completion:((updateStatus: ListUpdateStatus) -> ())?) {
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
    setIsReloading(true)
    let request = NSMutableURLRequest(URL: hostsFile)
    request.HTTPMethod = "HEAD"
    let session = NSURLSession.sharedSession()
    
    let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error -> Void in
      
      var result = ListUpdateStatus.UpdateSuccessful
      
      defer {
        if completion != nil {
          dispatch_async(dispatch_get_main_queue(), { () -> Void in
            completion!(updateStatus: result)
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
      
      
      let defaults = NSUserDefaults.init(suiteName: "group.com.refabricants.blackhole")
      
      if let candidateEtag = httpResp.allHeaderFields["Etag"] as? NSString {
        if let currentEtag = defaults!.objectForKey("blacklistEtag") as? NSString {
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
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
    setIsReloading(true)
    let documentDirectory =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
    let localFile = documentDirectory.URLByAppendingPathComponent("downloadedBlocklist.txt")
    print(localFile)
    
    guard let myHostsFileFromUrl = NSData(contentsOfURL: hostsFile) else {
      throw ListUpdateStatus.ErrorDownloading
    }
    guard myHostsFileFromUrl.writeToURL(localFile, atomically: true) else {
      throw ListUpdateStatus.ErrorSavingToLocalFilesystem
    }
    return localFile
  }
  
  
  static func createBlockerListJSON(blockList: NSURL) -> (updateStatus: ListUpdateStatus, blacklistFileType: String?, numberOfEntries: Int?) {
    print("\nEntering: \(__FUNCTION__)\n")
    setIsReloading(true)
    var updateStatus = ListUpdateStatus.UpdateSuccessful
    let fileManager = NSFileManager.defaultManager()
    let sharedFolder = fileManager.containerURLForSecurityApplicationGroupIdentifier("group.com.refabricants.blackhole")! as NSURL
    
    let blockerListURL = sharedFolder.URLByAppendingPathComponent("blockerList.json")
    let wildcardBlockerListURL = sharedFolder.URLByAppendingPathComponent("wildcardBlockerList.json")
    
    var wildcardDomains: Set<String>
    var blocklistFileType = "hosts"
    var numberOfEntries = 0
    var jsonSet = [[String: [String: String]]]()
    var jsonWildcardSet = [[String: [String: String]]]()
    var blockerListEntry = ""
    var wildcardBlockerListEntry = ""
    
    let data = NSData(contentsOfURL: blockList)
    
    if let jsonArray = JSON(data: data!).arrayObject {
      if NSJSONSerialization.isValidJSONObject(jsonArray) {
        
        for element in jsonArray {
          
          guard let newElement = element as? [String : [String : String]] else {
            return (ListUpdateStatus.InvalidJSON, nil, nil)
          }
          
          guard newElement.keys.count == 2 else {
            return (ListUpdateStatus.InvalidJSON, nil, nil)
          }
          
          let hasAction = contains(Array(newElement.keys), text: "action")
          let hasTrigger = contains(Array(newElement.keys), text: "trigger")
          
          guard hasAction && hasTrigger else {
            return (ListUpdateStatus.InvalidJSON, nil, nil)
          }
          
          numberOfEntries++
        }
        
        do {
          _ = try? fileManager.removeItemAtURL(blockerListURL)
          try fileManager.moveItemAtURL(blockList, toURL: blockerListURL)
        } catch {
          return (ListUpdateStatus.ErrorSavingToLocalFilesystem, nil, nil)
        }
        blocklistFileType = "JSON"
      }
      
      
    } else {
      
      let validFirstChars = "01234567890abcdef"
      
      _ = try? NSFileManager.defaultManager().removeItemAtPath(blockerListURL.path!)
      _ = try? NSFileManager.defaultManager().removeItemAtPath(wildcardBlockerListURL.path!)
      
      guard let sr = StreamReader(path: blockList.path!) else {
        return (ListUpdateStatus.ErrorParsingFile, nil, nil)
      }
      
      guard let blockerListStream = NSOutputStream(toFileAtPath: blockerListURL.path!, append: true) else {
        return (ListUpdateStatus.ErrorSavingParsedFile, nil, nil)
      }
      
      guard let wildcardBlockerListStream = NSOutputStream(toFileAtPath: wildcardBlockerListURL.path!, append: true) else {
        return (ListUpdateStatus.ErrorSavingParsedFile, nil, nil)
      }
      
      blockerListStream.open()
      wildcardBlockerListStream.open()
      
      defer {
        sr.close()
        
        blockerListStream.write("]")
        blockerListStream.close()
        
        wildcardBlockerListStream.write("]")
        wildcardBlockerListStream.close()
      }
      
      var firstCharInEntry = "["
      
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
            
            let urlFilter = components.joinWithSeparator("\\\\.")
            var wildcardURLFilter: String
            
            if ((components.count > 2) && (components[0].rangeOfString("www?\\d{0,3}", options: .RegularExpressionSearch) != nil)) {
              wildcardURLFilter = components[1..<components.count].joinWithSeparator("\\\\.")
            } else {
              wildcardURLFilter = components.joinWithSeparator("\\\\.")
            }
            
            numberOfEntries++
            blockerListEntry = ("\(firstCharInEntry){\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\"\(urlFilter)\"}}")
            wildcardBlockerListEntry = ("\(firstCharInEntry){\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\"\(wildcardURLFilter)\"}}")
            firstCharInEntry = ","
            
            blockerListStream.write(blockerListEntry)
            wildcardBlockerListStream.write(wildcardBlockerListEntry)
          }
        }
      }
    }
    _ = try? NSFileManager.defaultManager().removeItemAtPath(blockList.path!)
    
    if numberOfEntries > 50000 {
      updateStatus = ListUpdateStatus.TooManyEntries
    }
    
    setIsReloading(false)
    return (updateStatus, blocklistFileType, numberOfEntries)
  }

  
  static func contains(elements: Array<String>, text: String) -> Bool {
    
    for element in elements {
      if (element.caseInsensitiveCompare(text) == NSComparisonResult.OrderedSame) {
        return true
      }
    }
    return false
  }
  
}