//
//  blacklistURLEntryTableViewController.swift
//  AdScrubber
//
//  Created by David Westgate on 1/18/16.
//  Copyright © 2016 Refabricants. All rights reserved.
//
/*
blacklistURLTextView.delegate = self
blacklistURLTextView.returnKeyType = .Done

func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
if (text == "\n") {
textView.resignFirstResponder()
self.reloadButtonPressed(self)
}
return true
}


func endEditing() {
view.endEditing(true)
}

// in viewdidload
view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "endEditing"))
*/

import UIKit

class blacklistURLEntryTableViewController: UITableViewController, UITextViewDelegate {
  
  var incumbantBlacklistURL = BlackholeList.displayedBlacklist.getValueForKey("URL")
  
  @IBOutlet weak var blacklistURLTextView: UITextView!
  @IBOutlet weak var cancelButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    blacklistURLTextView.delegate = self
    blacklistURLTextView.text = incumbantBlacklistURL
    blacklistURLTextView.becomeFirstResponder()
    
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: - Table view data source
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    // #warning Incomplete implementation, return the number of sections
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // #warning Incomplete implementation, return the number of rows
    return 1
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
  
  
  // kudos to: http://stackoverflow.com/questions/27652227/text-view-placeholder-swift
  func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
    
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
  
  /*
  // Override to support conditional editing of the table view.
  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
  // Return false if you do not want the specified item to be editable.
  return true
  }
  */
  
  /*
  // Override to support editing the table view.
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
  if editingStyle == .Delete {
  // Delete the row from the data source
  tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
  } else if editingStyle == .Insert {
  // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
  }
  }
  */
  
  /*
  // Override to support rearranging the table view.
  override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
  
  }
  */
  
  /*
  // Override to support conditional rearranging of the table view.
  override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
  // Return false if you do not want the item to be re-orderable.
  return true
  }
  */
  
  /*
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  // Get the new view controller using segue.destinationViewController.
  // Pass the selected object to the new view controller.
  }
  */
  
}
