//
//  AppDelegate.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 28/02/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import UIKit

func app() -> UIViewController {
    let addButton = BarButton(title: BarButtonTitle.SystemItem(UIBarButtonSystemItem.Add), callback: { context in
        context.viewController.presentModal(rootViewController(loginViewController())) { loginInfo in
            println("Login info")
        }
    })
    
    let orgsVC: Screen<Organization> = resourceTableViewController(organizations(), standardCell { $0.login })
    
    let reposVC: Organization -> Screen<Repository> = { org in
        resourceTableViewController(org.reposResource, subtitleCell {
                    ($0.name, $0.description_)
            }, navigationItem: NavigationItem(title: org.login))
    }
    
    let issuesVC: Repository -> Screen<Issue> = { repo in
        resourceTableViewController(repo.issuesResource, subtitleCell { issue in
            let milestoneText = issue.milestone?.title ??  "<no milestone>"
            return (issue.title, "\(issue.creator.login) — \(issue.state.rawValue) — \(milestoneText)")
            }, navigationItem: NavigationItem(title: repo.name, rightBarButtonItem: addButton))
    }
    

    let issueBodyVC : Issue -> Screen<()> = { issue in
        return textViewController(issue.body ?? "")
    }

    let flow = rootViewController(orgsVC) >>> reposVC >>> issuesVC >>> issueBodyVC
    return flow.run { _ in }
    
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = app()
        window?.makeKeyAndVisible()
        return true
    }

}