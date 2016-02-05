//
//  ListUpdateStatus.swift
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

/// Used to signal the state of blacklist load operations
enum ListUpdateStatus: String, ErrorType {
  case UpdateSuccessful = "Ad Scrubber blocklist successfully updated"
  case NoUpdateRequired = "List already up-to-date"
  case NotHTTPS = "Error: link must be https"
  case InvalidURL = "Supplied URL is invalid"
  case ServerNotFound = "Unable to contact server"
  case NoSuchFile = "File not found"
  case UpdateRequired = "File is available - updating..."
  case ErrorDownloading = "File download interrupted"
  case UnexpectedDownloadError = "Unable to download file"
  case ErrorParsingFile = "Error parsing blocklist"
  case ErrorSavingToLocalFilesystem = "Unable to save downloaded file"
  case UnableToReplaceExistingBlockerlist = "Unable to replace existing blocklist"
  case ErrorSavingParsedFile = "Error saving parsed file"
  case TooManyEntries = "WARNING: blocklist size exceeds 50,000 entries. If Safari determines the size of the list will adversely impact performance it will ignore the new entries and continue using the rules from the last update."
  case InvalidJSON = "JSON file does not appear to be in valid Content Blocker format"
}