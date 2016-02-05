//
//  blacklistURLViewController.swift
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

import UIKit

/// Manages the user interface for updating the
/// blacklistURLTextView field of ViewController
class blacklistURLViewController: UITableViewController, UITextViewDelegate {

  // MARK: -
  // MARK: Control Outlets
  @IBOutlet weak var blacklistURLTextView: UITextView!
  @IBOutlet weak var cancelButton: UIButton!
  
  // MARK: Variables
  //
  var incumbantBlacklistURL = BlackholeList.displayedBlacklist.getValueForKey("URL")
  
  // MARK: Overridden functions
  override func viewDidLoad() {
    super.viewDidLoad()
    
    blacklistURLTextView.delegate = self
    blacklistURLTextView.text = incumbantBlacklistURL
    blacklistURLTextView.becomeFirstResponder()
  }

  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    
    BlackholeList.displayedBlacklist.setValueWithKey(blacklistURLTextView.text, forKey: "URL")
    BlackholeList.candidateBlacklist.setValueWithKey(blacklistURLTextView.text, forKey: "URL")
    
  }

  // MARK: Control Actions
  @IBAction func cancelButtonTouchUpInside(sender: AnyObject) {
    blacklistURLTextView.text = incumbantBlacklistURL
    blacklistURLTextView.textColor = UIColor.lightGrayColor()
    blacklistURLTextView.becomeFirstResponder()
    blacklistURLTextView.selectedTextRange = blacklistURLTextView.textRangeFromPosition(blacklistURLTextView.beginningOfDocument, toPosition: blacklistURLTextView.beginningOfDocument)
  }
  
  // MARK: Control Functions
  func textViewDidChangeSelection(textView: UITextView) {
    if self.view.window != nil {
      if textView.textColor == UIColor.lightGrayColor() {
        textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
      }
    }
  }
  
  
  func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
    
    guard (text != "\n") else {
      performSegueWithIdentifier("unwindToViewController", sender: nil)
      return false
    }
    
    let t: NSString = textView.text
    let updatedText = t.stringByReplacingCharactersInRange(range, withString:text)
    
    guard (updatedText != "") else {
      textView.text = incumbantBlacklistURL
      textView.textColor = UIColor.lightGrayColor()
      textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
      return false
    }

    if ((textView.textColor == UIColor.lightGrayColor()) && (updatedText != incumbantBlacklistURL)) {
      textView.text = nil
      textView.textColor = UIColor.blackColor()
    }
    
    return true
  }
  
}
