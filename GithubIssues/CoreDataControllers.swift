//
//  CoreDataControllers.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 07/06/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import FunctionalViewControllers

func coreDataTableViewController<A>(controller: ResultsController<A>, _ configuration: CellConfiguration<A>, navigationItem: NavigationItem = defaultNavigationItem) -> Screen<A> {
    return asyncTableVC({ callback in
        callback(controller.load())
        }, configuration, {
            controller.changeCallback = $0
        },navigationItem: navigationItem)
}