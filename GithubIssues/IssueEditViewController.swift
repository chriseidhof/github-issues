//
//  IssueEditViewController.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 08/03/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import UIKit
import FunctionalViewControllers

struct IssueInfo {
    let title: String
    let body: String
}

func issueEditViewController() -> Screen<IssueInfo> {
    return Screen { callback in
        var vc = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewControllerWithIdentifier("IssueEditViewController") as! IssueEditViewController
        vc.completion = callback
        return vc
    }
}

class IssueEditViewController: UIViewController {
    @IBOutlet var bodyField: UITextView!
    @IBOutlet var titleField: UITextField!
    var resizer: TextViewResizer?
    var completion: (IssueInfo -> ())?

    override func viewDidLoad() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "done:")
        resizer = TextViewResizer(textView: bodyField)
    }

    func done(sender: UIBarButtonItem) {
        let info = IssueInfo(title: self.titleField.text!, body: self.bodyField.text)
        completion?(info)
    }
}

class TextViewResizer: NSObject {
    let textView: UITextView

    init(textView: UITextView) {
        self.textView = textView
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)

    }

    @objc func keyboardWasShown(note: NSNotification) {
        if let userInfo = note.userInfo,
               value = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue
        {
            let rect = value.CGRectValue()
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: rect.size.height, right: 0)
            textView.contentInset = contentInsets
            textView.scrollIndicatorInsets = contentInsets
        }
    }

    @objc func keyboardWillHide(note: NSNotification) {
        textView.contentInset = UIEdgeInsetsZero
        textView.scrollIndicatorInsets = UIEdgeInsetsZero
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}