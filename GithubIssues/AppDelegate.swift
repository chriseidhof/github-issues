//
//  AppDelegate.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 28/02/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import UIKit
import FunctionalViewControllers

func app() -> UIViewController {

    let addButton : Repository -> BarButton = { repo in
        BarButton(title: BarButtonTitle.SystemItem(UIBarButtonSystemItem.Add), callback: { context in
            context.viewController.presentModal(navigationController(issueEditViewController()), cancellable: true) { issueInfo in
                let resource = repo.createIssueResource(issueInfo.title, body: issueInfo.body)
                request(resource, { issue in
                    println("Created issue \(issue)")
                })
            }
        })
    }

    
    let orgsScreen: LoginInfo -> Screen<Organization> = { loginInfo in
        var navigationItem = defaultNavigationItem
        navigationItem.title = "Organizations"
        return resourceTableViewController(organizations(), standardCell { organization in
            organization.login
        }, navigationItem: navigationItem)
    }
    

    let reposScreen: Organization -> Screen<Repository> = { org in
        var navigationItem = defaultNavigationItem
        navigationItem.title = org.login
        return resourceTableViewController(org.reposResource, subtitleCell { repo in
            (repo.name, repo.description_)
        }, navigationItem: navigationItem)
    }
    
    let issuesScreen: Repository -> Screen<Issue> = { repo in
        var navigationItem = defaultNavigationItem
        navigationItem.title = repo.name
        navigationItem.rightBarButtonItem = addButton(repo)

        return resourceTableViewController(repo.issuesResource, subtitleCell { issue in
            (issue.title, issue.state.rawValue)
        }, navigationItem: navigationItem)
    }
    
    let flow = navigationController(loginViewController()) >>> orgsScreen >>> reposScreen >>> issuesScreen

    return flow.run()
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