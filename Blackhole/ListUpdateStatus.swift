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
  case ErrorDownloading = "File download interrupted"
  case UnexpectedDownloadError = "Unable to download file"
  case ErrorParsingFile = "Error parsing blackhole list"
  case ErrorSavingToLocalFilesystem = "Unable to save downloaded file"
  case UnableToReplaceExistingBlockerlist = "Unable to replace existing blackhole list"
  case ErrorSavingParsedFile = "Error saving parsed file"
}