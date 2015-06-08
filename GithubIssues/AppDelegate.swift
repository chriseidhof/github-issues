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

func coreDataTableViewController<A>(controller: ResultsController<A>, configuration: CellConfiguration<A>, navigationItem: NavigationItem = defaultNavigationItem) -> Screen<A> {
    return asyncTableVC({ callback in
            callback(controller.load())
        }, configuration, registerUpdateCallback: {
            controller.changeCallback = $0
        },navigationItem: navigationItem)
}

func coreDataApp(context: NSManagedObjectContext) -> UIViewController {

    let orgsScreen: Screen<COrganization> = coreDataTableViewController(ResultsController(context: context), standardCell { $0.login } , navigationItem: defaultNavigationItem)

    let reposScreen: COrganization -> Screen<CRepository> = { (org: COrganization) in
        coreDataTableViewController(org.repositoriesController, standardCell { $0.name })
    }
    
    let issuesScreen: CRepository -> Screen<CIssue> = {
        coreDataTableViewController($0.issuesController, standardCell { $0.title })
    }
    

    let addIssue: CRepository -> BarButton = { repo in
        BarButton(title: BarButtonTitle.SystemItem(UIBarButtonSystemItem.Add)) { _ in
            let newIssue: CIssue = insert(context)
            newIssue.title = "New issue"
            newIssue.repository = repo
        }
    }
    
    let flow = navigationController(orgsScreen) >>> reposScreen >>> (issuesScreen <|> addIssue)
    
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
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = coreDataApp(context) // app()
        window?.makeKeyAndVisible()
        return true
    }

}