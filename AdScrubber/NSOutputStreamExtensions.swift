//
//  NSOutputStreamExtensions.swift
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
//
// From: http://stackoverflow.com/questions/26989493/how-to-open-file-and-append-a-string-in-it-swift

import Foundation

extension OutputStream {
  
  /// Write String to outputStream
  ///
  /// - parameter string:                The string to write.
  /// - parameter encoding:              The NSStringEncoding to use when writing the string. This will default to UTF8.
  /// - parameter allowLossyConversion:  Whether to permit lossy conversion when writing the string.
  ///
  /// - returns:                         Return total number of bytes written upon success. Return -1 upon failure.
  
  func write(_ string: String, encoding: String.Encoding = String.Encoding.utf8, allowLossyConversion: Bool = true) -> Int {
    if let data = string.data(using: encoding, allowLossyConversion: allowLossyConversion) {
      var bytes = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
      var bytesRemaining = data.count
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
