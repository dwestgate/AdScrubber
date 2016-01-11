//
//  ListUpdateStatus.swift
//  Blackhole
//
//  Created by David Westgate on 12/29/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//

import Foundation

enum ListUpdateStatus: String, ErrorType {
  case UpdateSuccessful = "Blackhole list successfully updated"
  case NoUpdateRequired = "List already up-to-date"
  case NotHTTPS = "Error: link must be https"
  case InvalidURL = "Supplied URL is invalid"
  case ServerNotFound = "Unable to contact server"
  case NoSuchFile = "File not found"
  case UpdateRequired = "File is available - updating..."
  case ErrorDownloading = "File download interrupted"
  case UnexpectedDownloadError = "Unable to download file"
  case ErrorParsingFile = "Error parsing blackhole list"
  case ErrorSavingToLocalFilesystem = "Unable to save downloaded file"
  case UnableToReplaceExistingBlockerlist = "Unable to replace existing blackhole list"
  case ErrorSavingParsedFile = "Error saving parsed file"
  case TooManyEntries = "WARNING: blocklist size exceeds 50,000 entries. If Safari determines the size of the list will adversely impact performance it will ignore the new entries and continue using the rules from the last update."
  case InvalidJSON = "JSON file does not appear to be in valid Content Blocker format"
}