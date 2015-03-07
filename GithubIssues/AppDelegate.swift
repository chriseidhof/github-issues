//
//  AppDelegate.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 28/02/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import UIKit

func loadResource<B>(r: Resource<B>) -> (B -> ()) -> () {
    return { completion in
        request(r) { oB in
            if let b = oB { completion(b) }
            else {
                let alertView = UIAlertView(title: "Error", message: "Couldn't load data", delegate: nil, cancelButtonTitle: "OK")
                alertView.show()
            }
        }
    }
}



func resourceTableViewController<B>(resource: Resource<[B]>, configuration: TableViewConfiguration<B>, navigationItem: NavigationItem = defaultNavigationItem) -> Screen<B> {
    return asyncTableVC(loadResource(resource), configuration, navigationItem: navigationItem)
}

//func resourceTableViewController<A,B>(f: A -> Resource<[B]>, configuration: TableViewConfiguration<B>, navigationItem: NavigationItem = defaultNavigationItem) -> A -> Screen<B> {
//return { a in
//    let x = loadResource(f)
//    return asyncTableViewController(loadResource(f), configuration, navigationItem: navigationItem)
//}
//}

func app() -> UIViewController {
    let addButton = BarButton(title: BarButtonTitle.SystemItem(UIBarButtonSystemItem.Add), callback: {
        println("Add")
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