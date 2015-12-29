//
//  ListUpdateStatus.swift
//  Blackhole
//
//  Created by David Westgate on 12/29/15.
//  Copyright © 2015 Refabricants. All rights reserved.
//

import Foundation

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
}