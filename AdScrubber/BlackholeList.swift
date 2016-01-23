//
//  BlackholeList.swift
//  AdScrubber
//
//  Created by David Westgate on 12/29/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//
//
// TODO: Animation stops when resuming
// TODO: Fix Block subdomains blocking description
// TODO: Have "Block subdomains" text go grey when it is unavailable
// TODO: Dismiss keyboard when "Reload list" is pressed
// TODO: Have "Reload list" change to "Load list" when there is a change to list of sites blocked
// TODO: Add a check box: "Use custom list"
//
/*
BlackholeList                   Struct connected to storage

sharedContainer                 "com.refabricants.adscrubber"
blacklistURL                    The remote URL of a blackhole list

blacklistEntryCount       the number of entries we count when adding a new blacklist
blacklistFileType               file type of the remote file
blacklistEtag                   the

*/



import Foundation
import SwiftyJSON
import SafariServices


struct BlackholeList {
  
  struct Blacklist {
    private let name: String
    
    init(withListName value: String, url: String, fileType: String, entryCount: String, etag: String) {
      name = value
      setValueWithKey(url, forKey: "URL")
      setValueWithKey(fileType, forKey: "FileType")
      setValueWithKey(entryCount, forKey: "EntryCount")
      setValueWithKey(etag, forKey: "Etag")
    }
    
    init(withListName: String, url: String, fileType: String) {
      name = withListName
      setValueWithKey(url, forKey: "\(name)BlacklistURL")
      setValueWithKey(fileType, forKey: "\(name)BlacklistFileType")
    }
    
    init(withListName: String) {
      name = withListName
    }
    
    func getValueForKey(key: String) -> String? {
      // return sharedContainer!.objectForKey("\(name)URL") as? String
      print("getValueForKey: \(name)Blacklist\(key)")
      if let value = sharedContainer!.objectForKey("\(name)Blacklist\(key)") as? String {
        return value
      } else {
        return nil
      }
    }
    
    func setValueWithKey(value: String, forKey: String) {
      print("setValueWithKey: \(name)Blacklist\(forKey)\n")
      sharedContainer!.setObject(value, forKey: "\(name)Blacklist\(forKey)")
    }
    
    func removeValueForKey(key: String) {
      sharedContainer!.removeObjectForKey("\(name)\(key)")
    }
    
  }
  
  // Set preloadedBlacklist etag
  static let sharedContainer = NSUserDefaults.init(suiteName: "group.com.refabricants.adscrubber")
  static var preloadedBlacklist = Blacklist(withListName: "preloaded", url: "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts", fileType: "built-in", entryCount: "27137", etag: "aaaa")
  static var defaultBlacklist = Blacklist(withListName: "default", url: "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts", fileType: "built-in")
  static var customBlacklist = Blacklist(withListName: "custom")
  static var candidateBlacklist = Blacklist(withListName: "candidate")
  
  static func getIsUseCustomBlocklistOn() -> Bool {
    if let value = sharedContainer!.boolForKey("isUseCustomBlocklistOn") as Bool? {
      return value
    } else {
      let value = false
      sharedContainer!.setBool(value, forKey: "isUseCustomBlocklistOn")
      return value
    }
  }
  
  
  static func setIsUseCustomBlocklistOn(value: Bool) {
    sharedContainer!.setBool(value, forKey: "isUseCustomBlocklistOn")
  }
  
  
  static func getDownloadedBlacklistType() -> String {
    if let value = sharedContainer!.objectForKey("downloadedBlacklistType") as? String {
      return value
    } else {
      let value = "none"
      sharedContainer!.setObject(value, forKey: "downloadedBlacklistType")
      return value
    }
  }
  
  
  static func setDownloadedBlacklistType(value: String) {
    sharedContainer!.setObject(value, forKey: "downloadedBlacklistType")
  }
  
  /*
  static func getPreloadedBlacklistURL() -> String {
    return "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
  }
  
  
  static func getDefaultBlacklistURL() -> String {
    return "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
  }
  
  
  static func getCustomBlacklistURL() -> String? {
    if let value = sharedContainer!.objectForKey("customBlacklistURL") as? String {
      return value
    } else {
      return nil
    }
  }
  
  
  static func setCustomBlacklistURL(value: String) {
    sharedContainer!.setObject(value, forKey: "customBlacklistURL")
  }
  
  
  static func getPreloadedBlacklistFileType() -> String {
    return "built-in"
  }
  
  
  static func getDefaultBlacklistFileType() -> String {
    return "hosts"
  }
  
  
  static func getCustomBlacklistFileType() -> String? {
    if let value = sharedContainer!.objectForKey("customBlacklistFileType") as? String {
      return value
    } else {
      return nil
    }
  }
  
  
  static func setCustomBlacklistFileType(value: String) {
    sharedContainer!.setObject(value, forKey: "customBlacklistFileType")
  }
  
  
  static func getPreloadedBlacklistEntryCount() -> String {
    return "27137"
  }
  
  
  static func getDefaultBlacklistEntryCount() -> String {
    if let value = sharedContainer!.objectForKey("defaultBlacklistEntryCount") as? String {
      return value
    } else {
      let value = "0"
      sharedContainer!.setObject(value, forKey: "defaultBlacklistEntryCount")
      return value
    }
  }
  
  
  static func setDefaultBlacklistEntryCount(value: String) {
    sharedContainer!.setObject(value, forKey: "defaultBlacklistEntryCount")
  }
  
  
  static func getCustomBlacklistEntryCount() -> String? {
    if let value = sharedContainer!.objectForKey("customBlacklistEntryCount") as? String {
      return value
    } else {
      return nil
    }
  }
  
  
  static func setCustomBlacklistEntryCount(value: String) {
    sharedContainer!.setObject(value, forKey: "customBlacklistEntryCount")
  }
  
  // TODO: get etag for preload
  static func getPreloadedBlacklistEtag() -> String {
    return "temp"
  }
  
  
  static func getDefaultBlacklistEtag() -> String? {
    if let value = sharedContainer!.objectForKey("defaultBlacklistEtag") as? String {
      return value
    } else {
      return nil
    }
  }
  
  
  static func setDefaultBlacklistEtag(value: String) {
    sharedContainer!.setObject(value, forKey: "defaultBlacklistEtag")
  }
  
  
  static func deleteDefaultBlacklistEtag() {
    sharedContainer!.removeObjectForKey("defaultBlacklistEtag")
  }
  
  
  static func getCustomBlacklistEtag() -> String? {
    if let value = sharedContainer!.objectForKey("customBlacklistEtag") as? String {
      return value
    } else {
      return nil
    }
  }
  
  
  static func setCustomBlacklistEtag(value: String) {
    sharedContainer!.setObject(value, forKey: "customBlacklistEtag")
  }
  
  
  static func deleteCustomBlacklistEtag() {
    sharedContainer!.removeObjectForKey("customBlacklistEtag")
  }
  */
  
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
    if let value = sharedContainer!.boolForKey("isBlockSubdomainsOn") as Bool? {
      return value
    } else {
      let value = false
      sharedContainer!.setBool(value, forKey: "isBlockSubdomainsOn")
      return value
    }
  }
  
  
  static func setIsBlockingSubdomains(value: Bool) {
    sharedContainer!.setBool(value, forKey: "isBlockSubdomainsOn")
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
      
      
      let defaults = NSUserDefaults.init(suiteName: "group.com.refabricants.adscrubber")
      
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
    let sharedFolder = fileManager.containerURLForSecurityApplicationGroupIdentifier("group.com.refabricants.adscrubber")! as NSURL
    
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
          
          guard let newElement = element as? [String : NSDictionary] else {
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
        
        blockerListStream.write("]}}]")
        blockerListStream.close()
        
        // wildcardBlockerListStream.write("]")
        wildcardBlockerListStream.write("]}}]")
        wildcardBlockerListStream.close()
      }
      
      var firstPartOfString = "[{\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\".*\",\"if-domain\":["
      
      while let line = sr.nextLine() {
        
        if ((!line.isEmpty) && (validFirstChars.containsString(String(line.characters.first!)))) {
          
          var uncommentedText = line
          
          if let commentPosition = line.characters.indexOf("#") {
            uncommentedText = line[line.startIndex.advancedBy(0)...commentPosition.predecessor()]
          }
          
          let lineAsArray = uncommentedText.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
          let listOfDomainsFromLine = lineAsArray.filter { $0 != "" }
          
          for entry in Array(listOfDomainsFromLine[1..<listOfDomainsFromLine.count]) {
            
            guard let validatedURL = NSURL(string: "http://" + entry) else { break }
            guard let validatedHost = validatedURL.host else { break }
            var components = validatedHost.componentsSeparatedByString(".")
            guard components[0].lowercaseString != "localhost" else { break }
            
            let domain = components.joinWithSeparator(".")
            
            numberOfEntries++
            blockerListEntry = ("\(firstPartOfString)\"\(domain)\"")
            wildcardBlockerListEntry = ("\(firstPartOfString)\"*\(domain)\"")
            firstPartOfString = ","
            
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