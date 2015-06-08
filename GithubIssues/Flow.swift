//
//  Flow.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 07/06/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import FunctionalViewControllers
import CoreData

func coreDataApp(context: NSManagedObjectContext) -> UIViewController {
    
    let orgsScreen: Screen<COrganization> = coreDataTableViewController(ResultsController(context: context), standardCell { $0.login } , navigationItem: defaultNavigationItem)
    
    let reposScreen: COrganization -> Screen<CRepository> = { (org: COrganization) in
        coreDataTableViewController(org.repositoriesController, standardCell { $0.name })
    }
    
    let issuesScreen: CRepository -> Screen<CIssue> = {
        coreDataTableViewController($0.issuesController, standardCell { $0.title })
    }
    
    let addIssue: CRepository -> BarButton = { repo in
        add(issueEditViewController()) { issueInfo in
            let newIssue: CIssue = insert(context)
            newIssue.title = issueInfo.title
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