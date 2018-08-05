//
//  BlackholeList.swift
//  AdScrubber
//
//  Created by David Westgate on 12/31/15.
//  Copyright © 2016 David Westgate
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions: The above copyright
// notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE

import Foundation
import SwiftyJSON
import SafariServices

/// Provides functions for downloading and creating JSON ContentBlocker lists
struct BlackholeList {
  
  // MARK: -
  // MARK: Metadata Handling
  /// Stores metadata associated with a blacklist
  struct Blacklist {
    
    /// The name of the blacklist
    fileprivate let name: String
    
    /**
        Writes the metadata for a new blacklist to the default store
     
        - Parameters:
          - value: The name of the list
          - url: The list's URL
          - fileType: The format of file containing the list (JSON, hosts, or built-in)
          - entryCount: The number of rules in the list
          - etag: The HTML etag value of the list at its URL
     */
    init(withListName value: String, url: String, fileType: String, entryCount: String, etag: String) {
      name = value
      setValueWithKey(url, forKey: "URL")
      setValueWithKey(fileType, forKey: "FileType")
      setValueWithKey(entryCount, forKey: "EntryCount")
      setValueWithKey(etag, forKey: "Etag")
    }
    
    /**
        Writes the metadata for a new blacklist to the default store
     
        - Parameters:
          - withListName: The name of the list
          - url: The list's URL
          - fileType: The format of file containing the list (JSON, hosts, or built-in)
     */
    init(withListName: String, url: String, fileType: String) {
      name = withListName
      setValueWithKey(url, forKey: "URL")
      setValueWithKey(fileType, forKey: "FileType")
    }
    
    /**
        Writes the metadata for a new blacklist to the default store
     
        - Parameters:
          - withListName: The name of the list
     */
    init(withListName: String) {
      name = withListName
    }
    
    /**
        Given a key, returns the stored default value of that key or nil
     
        - Parameters:
          - key: The key for the value to be returned
     
        - Returns: The stored value or nil
     */
    func getValueForKey(_ key: String) -> String? {
      if let value = defaultContainer.object(forKey: "\(name)Blacklist\(key)") as? String {
        return value
      } else {
        return nil
      }
    }

    /**
        Given a key value pair, writes the value to the default store
     
        - Parameters:
          - value: The value to be stored
          - forKey: The key to be employed for writing the value
     */
    func setValueWithKey(_ value: String, forKey: String) {
      defaultContainer.set(value, forKey: "\(name)Blacklist\(forKey)")
    }
    
    /**
        Given a key, deletes from the store the key value pair
     
        - Parameters:
          - key: The key of the key value pair to be deleted
     */
    func removeValueForKey(_ key: String) {
      defaultContainer.removeObject(forKey: "\(name)\(key)")
    }

    
    /**
        Deletes all key value pairs that have been written to the
        default store that are associated with the list
     */
    func removeAllValues() {
      removeValueForKey("URL")
      removeValueForKey("FileType")
      removeValueForKey("EntryCount")
      removeValueForKey("Etag")
    }
    
  }
  
  // MARK: Constants
  /// Convenience var for accessing group.com.refabricants.adscrubber
  fileprivate static let sharedContainer = UserDefaults.init(suiteName: "group.com.refabricants.adscrubber")
  
  /// Convenience var for accessing the default container
  fileprivate static let defaultContainer = UserDefaults.standard
  
  // MARK: Variables
  /// Metadata for the bundled ContentBlocker blocklist
  static var preloadedBlacklist = Blacklist(withListName: "preloaded", url: "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts", fileType: "built-in", entryCount: "27167", etag: "9011c48902c695e9a92b259a859f971f7a9a5f75")
  
  /// Metadata for the currently loaded custom blocklist
  static var currentBlacklist = Blacklist(withListName: "current")
  
  /// Metadata for the blacklist stored in the TextView
  static var displayedBlacklist = Blacklist(withListName: "displayed")
  
  /// Metadata for the blacklist stored in the TextView but not yet validated or loaded
  static var candidateBlacklist = Blacklist(withListName: "candidate")
  
  // TODO: Move these to ViewController
  // MARK: List Metadata Getters/Setters
  /**
      Reads the value in the shared storage container that determines whether
      or not a blacklist should be used. Returns the value or, if no value is
      found in shared storage, sets it to false and returns false.
   
      - Returns: A boolean value indicating whether or not a custom blacklist
                should be used
   */
  static func getIsUseCustomBlocklistOn() -> Bool {
    if let value = sharedContainer!.bool(forKey: "isUseCustomBlocklistOn") as Bool? {
      return value
    } else {
      let value = false
      sharedContainer!.set(value, forKey: "isUseCustomBlocklistOn")
      return value
    }
  }
  
  /**
      Sets the value in the shared storage container that determines whether
      or not a custom blacklist shouldbe used
   
      - Parameters:
        - value: True if a custom blacklist should be used, false otherwise
   */
  static func setIsUseCustomBlocklistOn(_ value: Bool) {
    sharedContainer!.set(value, forKey: "isUseCustomBlocklistOn")
  }
  
  /**
      Reads the value in the shared storage container that contains the
      blacklist file type. Returns the file type (i.e. "built-in", "JSON",
      or "hosts" or, if no value is found in shared storage, sets the
      value to "none."
   
      - Returns: The file type of the currently-loaded blacklist, or "none"
   */
  static func getDownloadedBlacklistType() -> String {
    if let value = sharedContainer!.object(forKey: "downloadedBlacklistType") as? String {
      return value
    } else {
      let value = "none"
      sharedContainer!.set(value, forKey: "downloadedBlacklistType")
      return value
    }
  }
  
  /**
      Sets the value in the shared storage container that contains the
      blacklist file type.
   
      - Parameters:
        - value: The file type of the blacklist (i.e. "built-in", "JSON",
                or "hosts")
   */
  static func setDownloadedBlacklistType(_ value: String) {
    sharedContainer!.set(value, forKey: "downloadedBlacklistType")
  }
  
  /**
      Reads the value in the shared storage container that indicates whether
      a new blacklist is in the process of being downloaded. Returns the value
      or, if no value is found in shared storage, sets it to false and returns
      false.
   
      - Returns: A boolean value indicating whether or not a blacklist is
                in the process of being downloaded
   */
  static func getIsReloading() -> Bool {
    if let value = sharedContainer!.bool(forKey: "isReloading") as Bool? {
      return value
    } else {
      let value = false
      sharedContainer!.set(value, forKey: "isReloading")
      return value
    }
  }
  
  /**
      Sets the value in the shared storage container that indicates whether
      or not a new blacklist is in the process of being downloaded.
   
      - Parameters:
        - value: A boolean value indicating whether or not a blacklist is
                in the process of being downloaded
   */
  static func setIsReloading(_ value: Bool) {
    sharedContainer!.set(value, forKey: "isReloading")
  }
  
  /**
      Reads the value in the shared storage container that indicates whether
      the "wildcardBlockerList.json" file should be loaded instead of the
      default "blockerList.json" file.
   
      - Returns: A boolean value indicating whether or not the
                "wildcardBlockerList.json" file should be loaded
   */
  static func getIsBlockingSubdomains() -> Bool {
    if let value = sharedContainer!.bool(forKey: "isBlockSubdomainsOn") as Bool? {
      return value
    } else {
      let value = false
      sharedContainer!.set(value, forKey: "isBlockSubdomainsOn")
      return value
    }
  }
  
  /**
      Sets the value in the shared storage container that indicates whether
      the "wildcardBlockerList.json" file should be loaded instead of the
      default "blockerList.json" file.
   
      - Parameters:
        - value: A boolean value indicating whether or not the
                "wildcardBlockerList.json" file should be loaded
   */
  static func setIsBlockingSubdomains(_ value: Bool) {
    sharedContainer!.set(value, forKey: "isBlockSubdomainsOn")
  }
  
  // MARK: BlackholeList Functions
  /**
      Fetches information on the URL of a blacklist and determines
      whether or not the blacklist can and should be downloaded.
      If the file can be downloaded, "should be downloaded" is
      determined by comparing the remote file's etag to the etag
      in the metadata recorded when the current file was loaded.
   
      - Parameters:
        - blacklistURL: The URL of the blacklist to be validated
   */
  static func validateURL(_ blacklistURL:URL, completion:((_ updateStatus: ListUpdateStatus) -> ())?) {

    setIsReloading(true)
    let request = NSMutableURLRequest(url: blacklistURL)
    request.httpMethod = "HEAD"
    let session = URLSession.shared
    
    let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
      
      var result = ListUpdateStatus.UpdateSuccessful
      
      defer {
        if completion != nil {
          DispatchQueue.main.async(execute: { () -> Void in
            completion!(updateStatus: result)
          })
        }
      }
      
      guard let httpResp: HTTPURLResponse = response as? HTTPURLResponse else {
        result = ListUpdateStatus.ServerNotFound
        return
      }
      
      guard httpResp.statusCode == 200 else {
        result = ListUpdateStatus.NoSuchFile
        return
      }
      
      if let candidateEtag = httpResp.allHeaderFields["Etag"] as? NSString {
        if let currentEtag = currentBlacklist.getValueForKey("Etag") {
          if candidateEtag.isEqual(currentEtag) {
            result = ListUpdateStatus.NoUpdateRequired
          } else {
            currentBlacklist.setValueWithKey(candidateEtag as String, forKey: "Etag")
          }
        } else {
          currentBlacklist.setValueWithKey(candidateEtag as String, forKey: "Etag")
        }
      } else {
        currentBlacklist.removeValueForKey("Etag")
      }
    })
    
    task.resume()
  }
  
  /**
      Downloads a remote blacklist
   
      - Parameters:
        - blacklistURL: The URL of the blacklist to be downloaded
   
      - Throws: ListUpdateStatus
        - .ErrorDownloading: The download failed
        - .ErrorSavingToLocalFilesystem: Saving the downloaded file failed
   
      - Returns: The locally-saved file
   */
  static func downloadBlacklist(_ blacklistURL: URL) throws -> URL? {

    setIsReloading(true)
    let documentDirectory =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
    let localFile = documentDirectory.appendingPathComponent("downloadedBlocklist.txt")
    
    guard let myblacklistURLFromUrl = try? Data(contentsOf: blacklistURL) else {
      throw ListUpdateStatus.ErrorDownloading
    }
    guard (try? myblacklistURLFromUrl.write(to: localFile, options: [.atomic])) != nil else {
      throw ListUpdateStatus.ErrorSavingToLocalFilesystem
    }
    return localFile
  }
  
  /**
      If the downloaed blacklist is a JSON file, replaces the exiting
      "blockerList.json" file in the shared container with the downloaded
      file.
   
      If the downloaded blacklist is a hosts file, parses the downloaded file
      and uses the entries to create both a "blockerList.json" file and
      a "wildcardBlockerList.json" file in the shared container. The latter
      list adds a wildcard prefix to every rule to block subdomains.
   
      - Parameters:
        - blacklist: The URL of the downloaded blacklist
   
      - Returns:
        - updateStatus:
          - .UpdateSuccessful: The operation was successful
          - .InvalidJSON: A JSON file was detected, but the file does not conform to expected Content Blocker syntax
          - .ErrorSavingToLocalFilesystem: An error occurred moving the file to the shared container
          - .ErrorParsingFile: A hosts file was detected, but the an error occurred while parsing it
          - .TooManyEntries: There are more than 50,000 rule entries
        - blacklistFileType: "JSON" or "hosts," depending upon which file type was detected
        - numberOfEntries: The number of entries detected in the blacklist
   */
  static func createBlockerListJSON(_ blacklist: URL) -> (updateStatus: ListUpdateStatus, blacklistFileType: String?, numberOfEntries: Int?) {

    setIsReloading(true)
    var updateStatus = ListUpdateStatus.UpdateSuccessful
    let fileManager = FileManager.default
    let sharedFolder = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.refabricants.adscrubber")! as URL
    
    let blockerListURL = sharedFolder.appendingPathComponent("blockerList.json")
    let wildcardBlockerListURL = sharedFolder.appendingPathComponent("wildcardBlockerList.json")
    
    var wildcardDomains: Set<String>
    var blacklistFileType = "hosts"
    var numberOfEntries = 0
    var jsonSet = [[String: [String: String]]]()
    var jsonWildcardSet = [[String: [String: String]]]()
    var blockerListEntry = ""
    var wildcardBlockerListEntry = ""
    
    let data = try? Data(contentsOf: blacklist)
    
    if let jsonArray = JSON(data: data!).arrayObject {
      if JSONSerialization.isValidJSONObject(jsonArray) {
        
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
          _ = try? fileManager.removeItem(at: blockerListURL)
          try fileManager.moveItem(at: blacklist, to: blockerListURL)
        } catch {
          return (ListUpdateStatus.ErrorSavingToLocalFilesystem, nil, nil)
        }
        blacklistFileType = "JSON"
      }
      
    } else {
      
      let validFirstChars = "01234567890abcdef"
      
      _ = try? FileManager.default.removeItem(atPath: blockerListURL.path)
      _ = try? FileManager.default.removeItem(atPath: wildcardBlockerListURL.path)
      
      guard let sr = StreamReader(path: blacklist.path) else {
        return (ListUpdateStatus.ErrorParsingFile, nil, nil)
      }
      
      guard let blockerListStream = OutputStream(toFileAtPath: blockerListURL.path, append: true) else {
        return (ListUpdateStatus.ErrorSavingParsedFile, nil, nil)
      }
      
      guard let wildcardBlockerListStream = OutputStream(toFileAtPath: wildcardBlockerListURL.path, append: true) else {
        return (ListUpdateStatus.ErrorSavingParsedFile, nil, nil)
      }
      
      blockerListStream.open()
      wildcardBlockerListStream.open()
      
      defer {
        sr.close()
        
        blockerListStream.write("]}}]", maxLength: <#Int#>)
        blockerListStream.close()
        
        wildcardBlockerListStream.write("]}}]", maxLength: <#Int#>)
        wildcardBlockerListStream.close()
      }
      
      var firstPartOfString = "[{\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\".*\",\"resource-type\":[\"script\"],\"load-type\":[\"third-party\"]}},"
        
      firstPartOfString += "{\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\".*\",\"if-domain\":["
      
      while let line = sr.nextLine() {
        
        if ((!line.isEmpty) && (validFirstChars.contains(String(line.characters.first!)))) {
          
          var uncommentedText = line
          
          if let commentPosition = line.characters.index(of: "#") {
            uncommentedText = line[line.characters.index(line.startIndex, offsetBy: 0)...<#T##String.CharacterView corresponding to `commentPosition`##String.CharacterView#>.index(before: commentPosition)]
          }
          
          let lineAsArray = uncommentedText.components(separatedBy: CharacterSet.whitespaces)
          let listOfDomainsFromLine = lineAsArray.filter { $0 != "" }
          
          for entry in Array(listOfDomainsFromLine[1..<listOfDomainsFromLine.count]) {
            
            guard let validatedURL = URL(string: "http://" + entry) else { break }
            guard let validatedHost = validatedURL.host else { break }
            var components = validatedHost.components(separatedBy: ".")
            guard components[0].lowercased() != "localhost" else { break }
            
            let domain = components.joined(separator: ".")
            
            numberOfEntries += 1
            blockerListEntry = ("\(firstPartOfString)\"\(domain)\"")
            wildcardBlockerListEntry = ("\(firstPartOfString)\"*\(domain)\"")
            firstPartOfString = ","
            
            blockerListStream.write(blockerListEntry, maxLength: <#Int#>)
            wildcardBlockerListStream.write(wildcardBlockerListEntry, maxLength: <#Int#>)
          }
        }
      }
    }
    _ = try? FileManager.default.removeItem(atPath: blacklist.path)
    
    if numberOfEntries > 50000 {
      updateStatus = ListUpdateStatus.TooManyEntries
    }
    
    setIsReloading(false)
    return (updateStatus, blacklistFileType, numberOfEntries)
  }
  
  // MARK: Helper Functions
  /**
      Ignoring case, determines whether or not an array contains a particular string
   
      - Parameters:
        - elements: An arrray of strings
        - text: The string to search for
   
      - Returns: **true** if *text* occurs in *elements*, **false** otherwise
   */
  static func contains(_ elements: Array<String>, text: String) -> Bool {
    
    for element in elements {
      if (element.caseInsensitiveCompare(text) == ComparisonResult.orderedSame) {
        return true
      }
    }
    return false
  }
  
}
