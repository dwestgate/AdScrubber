//
//  ListUpdateStatus.swift
//  Blackhole
//
//  Created by David Westgate on 12/29/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//

import Foundation

enum ListUpdateStatus: String, ErrorType {
  case UpdateSuccessful = "Blackhole list successfuly updated"
  case NoUpdateRequired = "No update needed"
  case NotHTTPS = "Error: link must be https"
  case InvalidURL = "Supplied URL is invalid"
  case ServerNotFound = "Unable to contact server"
  case NoSuchFile = "File not found"
  case UpdateRequired = "File is available - updating..."
  case ErrorDownloading = "Download interrupted"
  case ErrorDownloadingFromRemoteLocation
  case ErrorSavingToLocalFilesystem
  case ErrorParsingFile = "Error parsing blackhole list"
  case UnableToReplaceExistingBlockerlist
  case ErrorSavingParsedFile = "Error saving parsed file"
}