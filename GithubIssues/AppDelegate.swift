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

func coreDataTableViewController<A: CoreDataObject>(context: NSManagedObjectContext, configuration: CellConfiguration<A>, navigationItem: NavigationItem = defaultNavigationItem) -> Screen<A> {
    return asyncTableVC({ callback in
        callback(results(context))
    }, configuration, navigationItem: navigationItem)
}

func coreDataApp(context: NSManagedObjectContext) -> UIViewController {
    let orgsScreen: LoginInfo -> Screen<COrganization> = { loginInfo in
        var navigationItem = defaultNavigationItem
        navigationItem.title = "Organizations"
        return coreDataTableViewController(context, standardCell { organization in
            organization.login
            }, navigationItem: navigationItem)
    }
    
    let reposScreen: COrganization -> Screen<CRepository> = { org in
        var navigationItem = defaultNavigationItem
        navigationItem.title = org.login
        return asyncTableVC({ callback in
            callback(org.repositories)
            }, standardCell { (repo: CRepository) in repo.name }, navigationItem: navigationItem)
    }
    
    
    let flow = navigationController(loginViewController()) >>> orgsScreen >>> reposScreen
    
    return flow.run()
}

func app() -> UIViewController {
    let addButton : Repository -> BarButton = { repo in
        add(issueEditViewController()) { issueInfo in
            request(repo.createIssueResource(issueInfo.title, body: issueInfo.body))
        }
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
        return resourceTableViewController(repo.issuesResource, subtitleCell { issue in
            (issue.title, issue.state.rawValue)
        }, navigationItem: navigationItem)
    }
    
    let flow = navigationController(loginViewController()) >>> orgsScreen >>> reposScreen >>> (issuesScreen <|> addButton)

    return flow.run()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let context = setupStack()
        let z: CUser = insert(context)

        let users: [CUser] = results(context)
        seed(context)
        println(users)
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = coreDataApp(context) // app()
        window?.makeKeyAndVisible()
        return true
    }

}