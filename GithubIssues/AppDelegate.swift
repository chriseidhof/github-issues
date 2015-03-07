//
//  AppDelegate.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 28/02/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import UIKit

func loadResource<A,B>(r: A -> Resource<B>) -> (A, B -> ()) -> () {
    return { initial, completion in
        request(r(initial)) { oB in
            if let b = oB { completion(b) }
            else {
                let alertView = UIAlertView(title: "Error", message: "Couldn't load data", delegate: nil, cancelButtonTitle: "OK")
                alertView.show()
            }
        }
    }
}

func resourceTableViewController<A,B>(f: A -> Resource<[B]>, configuration: TableViewConfiguration<B>, navigationItem: NavigationItem = defaultNavigationItem) -> Screen<A,B> {
    let x = loadResource(f)
    return asyncTableViewController(loadResource(f), configuration, navigationItem: navigationItem)
}

func app() -> UIViewController {
    let start = rootViewController(loginViewController())
    
    let starButton = BarButton(title: "*", callback: {
        println("Star")
    })

    let orgsVC : Screen<(), Organization> = resourceTableViewController({ _ in organizations() }, standardCell { $0.login }, navigationItem: NavigationItem(title: "Organizations", rightBarButtonItem: starButton))
    
    let reposVC : Screen<Organization, Repository> = resourceTableViewController({ $0.reposResource }, subtitleCell {
        ($0.name, $0.description_)
        }, navigationItem: NavigationItem(title: "Repositories") )
    
    let issuesVC: Screen<Repository, Issue> =
    resourceTableViewController({ $0.issuesResource }, subtitleCell { issue in
        let milestoneText = issue.milestone?.title ??  "<no milestone>"
        return (issue.title, "\(issue.creator.login) — \(issue.state.rawValue) — \(milestoneText)")
    } )
    
    let issueBodyVC: Screen<String, ()> = textViewController()
    
    let flow = rootViewController(orgsVC) >>> reposVC >>> issuesVC >>> select(issueBodyVC, { $0.body ?? "" })
    
    return run(flow, ()) { _ in }
    
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