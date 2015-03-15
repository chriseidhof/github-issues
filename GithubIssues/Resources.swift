//
//  Resources.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 07/03/15.
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



public func resourceTableViewController<B>(resource: Resource<[B]>, configuration: TableViewConfiguration<B>, navigationItem: NavigationItem = defaultNavigationItem) -> Screen<B> {
    return asyncTableVC(loadResource(resource), configuration, navigationItem: navigationItem)
}
