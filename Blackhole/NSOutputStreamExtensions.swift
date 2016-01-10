//
//  NSOutputStreamExtensions.swift
//  Blackhole
//
//  Created by David Westgate on 1/9/16.
//  Copyright © 2016 Refabricants. All rights reserved.
//
//  Extension from: http://stackoverflow.com/questions/26989493/how-to-open-file-and-append-a-string-in-it-swift

import Foundation

extension NSOutputStream {
  
  /// Write String to outputStream
  ///
  /// - parameter string:                The string to write.
  /// - parameter encoding:              The NSStringEncoding to use when writing the string. This will default to UTF8.
  /// - parameter allowLossyConversion:  Whether to permit lossy conversion when writing the string.
  ///
  /// - returns:                         Return total number of bytes written upon success. Return -1 upon failure.
  
  func write(string: String, encoding: NSStringEncoding = NSUTF8StringEncoding, allowLossyConversion: Bool = true) -> Int {
    if let data = string.dataUsingEncoding(encoding, allowLossyConversion: allowLossyConversion) {
      var bytes = UnsafePointer<UInt8>(data.bytes)
      var bytesRemaining = data.length
      var totalBytesWritten = 0
      
      while bytesRemaining > 0 {
        let bytesWritten = self.write(bytes, maxLength: bytesRemaining)
        if bytesWritten < 0 {
          return -1
        }
        
        bytesRemaining -= bytesWritten
        bytes += bytesWritten
        totalBytesWritten += bytesWritten
      }
      
      return totalBytesWritten
    }
    
    return -1
  }
  
}