//
//  LoginViewController.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 28/02/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import UIKit

func loginViewController() -> Screen<(), LoginInfo> {
    return Screen({ _, callback in
        var vc = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
        vc.completion = callback
        return vc
    })
}

struct LoginInfo {
    let password: String
    let username: String
}

class LoginViewController: UITableViewController {
    @IBOutlet var username: UITextField?
    @IBOutlet var password: UITextField?
    var completion: (LoginInfo -> ())?
    
    @IBAction func login(sender: UIBarButtonItem) {
        if let u = username?.text, p = password?.text {
            completion?(LoginInfo(password: p, username: u))
        }
    }
}