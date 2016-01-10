//
//  BlackholeList.swift
//  Blackhole
//
//  Created by David Westgate on 12/28/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//
// TODO - Ensure I overwrite downloaded files!
// TODO - When converting to JSON, convert in chunks
// TODO - Eliminate whitespace in JSON

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
  
  static func validateURL(hostsFile:NSURL, completion:((urlStatus: ListUpdateStatus) -> ())?) {
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
    let request = NSMutableURLRequest(URL: hostsFile)
    request.HTTPMethod = "HEAD"
    let session = NSURLSession.sharedSession()
    
    let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error -> Void in
      
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
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
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
  
  
  static func createBlockerListJSON(blockList: NSURL) -> Int {
    print("\nEntering: \(__FUNCTION__)\n")
    var numberOfEntries = 0
    var jsonSet = [[String: [String: String]]]()
    var jsonWildcardSet = [[String: [String: String]]]()
    var blockerListBuffer = ""
    var wildcardBlockerListBuffer = ""
    
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
      
      let validFirstChars = "01234567890abcdef"
      
      let sharedFolder = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.refabricants.blackhole")! as NSURL
      
      let blockerListURL = sharedFolder.URLByAppendingPathComponent("blockerList.json")
      let wildcardBlockerListURL = sharedFolder.URLByAppendingPathComponent("wildcardBlockerList.json")
      
      _ = try? NSFileManager.defaultManager().removeItemAtPath(blockerListURL.path!)
      _ = try? NSFileManager.defaultManager().removeItemAtPath(wildcardBlockerListURL.path!)
      
      guard let sr = StreamReader(path: blockList.path!) else {
        // return ListUpdateStatus.ErrorParsingFile
        return 0
      }
      
      guard let blockerListStream = NSOutputStream(toFileAtPath: blockerListURL.path!, append: true) else {
        // return ListUpdateStatus.ErrorSavingParsedFile
        return 0
      }
      
      guard let wildcardBlockerListStream = NSOutputStream(toFileAtPath: wildcardBlockerListURL.path!, append: true) else {
        // return ListUpdateStatus.ErrorSavingParsedFile
        return 0
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
      
      var count = 0
      
      var firstCharInBuffer = "["
      
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
              components[0] = ".*"
              wildcardURLFilter = components.joinWithSeparator("\\.")
            } else {
              wildcardURLFilter = ".*\\." + components.joinWithSeparator("\\.")
            }
            numberOfEntries++
            // jsonSet.append(["action": ["type": "block"], "trigger": ["url-filter":urlFilter]])
            blockerListBuffer += ("\(firstCharInBuffer){\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\"\(urlFilter)\"}}")
            // jsonWildcardSet.append(["action": ["type": "block"], "trigger": ["url-filter":wildcardURLFilter]])
            // wildcardBlockerListBuffer += ("\(firstCharInBuffer){\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\"\(urlFilter)}}")
            firstCharInBuffer = ","
            
            if (numberOfEntries % 10000) == 0 {
              print("We've processed \(numberOfEntries) entries")
            }
            
            // if count < 12 {
            //  count++
            // } else {
              count = 0
              
              blockerListStream.write(blockerListBuffer)
              // wildcardBlockerListStream.write(wildcardBlockerListBuffer)
              // appendWithJSON(blockerListStream, jsonArray: jsonSet)
              // appendWithJSON(wildcardBlockerListStream, jsonArray: jsonWildcardSet)
              blockerListBuffer = ""
              wildcardBlockerListBuffer = ""
              // jsonSet.removeAll()
              // jsonWildcardSet.removeAll()
            // }
          }
        }
        if count > 0 {
          blockerListStream.write(blockerListBuffer)
          // wildcardBlockerListStream.write(wildcardBlockerListBuffer)
          // appendWithJSON(blockerListStream, jsonArray: jsonSet)
          // appendWithJSON(wildcardBlockerListStream, jsonArray: jsonWildcardSet)
        }
      }
    }
    
    /*let valid = NSJSONSerialization.isValidJSONObject(jsonSet)
    print("JSON file is confirmed valid: \(valid). Number of elements = \(jsonSet.count)")
    
    return (jsonSet, jsonWildcardSet) */
    return numberOfEntries
  }
  
  private static func appendWithJSON(os: NSOutputStream, jsonArray: [[String: [String: String]]]) {
    // let blockerListJSON = JSON(jsonArray)
    let blockerListJSONText = jsonArray.description
    print("\nStraight text from the array looks like this: \(blockerListJSONText)")
    // let blockerListMap = blockerListJSON.flatMap(<#T##transform: ((String, JSON)) throws -> SequenceType##((String, JSON)) throws -> SequenceType#>)
    var blockerListText = blockerListJSONText.stringByReplacingOccurrencesOfString("[", withString: "{")
    blockerListText = blockerListText.stringByReplacingOccurrencesOfString("]", withString: "}")
    let newStartIndex = blockerListText.startIndex.advancedBy(1)
    let newEndIndex = blockerListText.endIndex.predecessor()
    
    os.write(blockerListText[newStartIndex..<newEndIndex])
  }
  
  
  static func writeBlockerlist(fileName: String, jsonArray: [[String: [String: String]]]) throws -> Void {
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
    let jsonPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.refabricants.blackhole")! as NSURL
    let destinationUrl = jsonPath.URLByAppendingPathComponent(fileName)
    print("Writing to file: \(destinationUrl)")
    
    let json = JSON(jsonArray)
    
    _ = try? NSFileManager.defaultManager().removeItemAtPath(destinationUrl.path!)
    
    do {
      try json.description.writeToFile(destinationUrl.path!, atomically: false, encoding: NSUTF8StringEncoding)
    } catch {
      throw ListUpdateStatus.UnableToReplaceExistingBlockerlist
    }
  }
  
  
  static func appendJSONToFileWithFileName(fileName: String, jsonArray: [[String: [String: String]]]) throws -> Void {
    print("\n>>> Entering: \(__FUNCTION__) <<<\n")
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

