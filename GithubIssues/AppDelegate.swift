//
//  AppDelegate.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 28/02/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import UIKit
import FunctionalViewControllers
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        let context = setupStack()
        seed(context)
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = coreDataApp(context) // app()
        window?.makeKeyAndVisible()
        return true
    }

}