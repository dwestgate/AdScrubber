//
//  blacklistURLViewController.swift
//  AdScrubber
//
//  Created by David Westgate on 1/18/16.
//  Copyright © 2016 Refabricants. All rights reserved.
//

import UIKit

class blacklistURLViewController: UITableViewController, UITextViewDelegate {
  
  var incumbantBlacklistURL = BlackholeList.displayedBlacklist.getValueForKey("URL")
  
  @IBOutlet weak var blacklistURLTextView: UITextView!
  @IBOutlet weak var cancelButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    blacklistURLTextView.delegate = self
    blacklistURLTextView.text = incumbantBlacklistURL
    blacklistURLTextView.becomeFirstResponder()

  }
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    print("We're here")
    return true
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  
  @IBAction func cancelButtonTouchUpInside(sender: AnyObject) {
    blacklistURLTextView.text = incumbantBlacklistURL
    blacklistURLTextView.textColor = UIColor.lightGrayColor()
    blacklistURLTextView.becomeFirstResponder()
    blacklistURLTextView.selectedTextRange = blacklistURLTextView.textRangeFromPosition(blacklistURLTextView.beginningOfDocument, toPosition: blacklistURLTextView.beginningOfDocument)
  }
  
  
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
  
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    
    BlackholeList.displayedBlacklist.setValueWithKey(blacklistURLTextView.text, forKey: "URL")
    BlackholeList.candidateBlacklist.setValueWithKey(blacklistURLTextView.text, forKey: "URL")
    
  }
  
}
