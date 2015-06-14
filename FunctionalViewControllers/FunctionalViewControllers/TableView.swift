//
//  TableView.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 28/02/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import UIKit

public func tableViewController<A>(configuration: CellConfiguration<A>) -> [A] -> Screen<A> {
    return { items in
        return asyncTableVC({ $0(items) }, configuration)
    }
}

public func standardCell<A>(f: A -> String) -> CellConfiguration<A> {
    var config: CellConfiguration<A> = CellConfiguration()
    config.render = { cell, a in
        cell.textLabel?.text = f(a)
    }
    return config
}

public func value1Cell<A>(f: A -> (title: String, subtitle: String)) -> CellConfiguration<A> {
    return twoTextCell(.Value1)(f)
}

public func subtitleCell<A>(f: A -> (title: String, subtitle: String)) -> CellConfiguration<A> {
    return twoTextCell(.Subtitle)(f)
}

public func value2Cell<A>(f: A -> (title: String, subtitle: String)) -> CellConfiguration<A> {
    return twoTextCell(.Value2)(f)
}

private func twoTextCell<A>(style: UITableViewCellStyle)(_ f: A -> (title: String, subtitle: String)) -> CellConfiguration<A> {
    return CellConfiguration(render: { (cell: UITableViewCell, a: A) in
        let (title, subtitle) = f(a)
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle
        }, style: style)
}

public struct CellConfiguration<A> {
    var render: (UITableViewCell, A) -> () = { _ in }
    var style: UITableViewCellStyle = UITableViewCellStyle.Default
}


public func asyncTableVC<A>(loadData: ([A] -> ()) -> (), configuration: CellConfiguration<A>, registerUpdateCallback: (([A] -> ()) -> ())? = nil, reloadable: Bool = true, navigationItem: NavigationItem = defaultNavigationItem) -> Screen<A> {
    return Screen(navigationItem) { callback in
        var myTableViewController = MyViewController(style: UITableViewStyle.Plain)
        myTableViewController.items = nil
        if let updateCallback = registerUpdateCallback {
            updateCallback { items in
                myTableViewController.items = items.map { Box($0) }
            }
        }
        loadData { myTableViewController.items = $0.map { Box($0) } }
        myTableViewController.cellStyle = configuration.style
        if reloadable {
            myTableViewController.reload = { (f: [AnyObject]? -> ()) in
                loadData {
                    f($0.map { Box($0) })
                }
            }
        }
        myTableViewController.configureCell = { cell, obj in
            if let boxed = obj as? Box<A> {
                configuration.render(cell, boxed.unbox)
            }
            return cell
        }
        myTableViewController.callback = { x in
            if let boxed = x as? Box<A> {
                callback(boxed.unbox)
            }
        }
        return myTableViewController
    }
}

extension UIBarButtonItem {

}

class MyViewController: UITableViewController {
    var cellStyle: UITableViewCellStyle = .Default
    var items: [AnyObject]? = [] {
        didSet {
            self.view.backgroundColor = items == nil ? UIColor.grayColor() : UIColor.whiteColor()
            self.tableView.reloadData()
        }
    }

    var reload: (([AnyObject]? -> ()) -> ())? {
        didSet {
            self.refreshControl = reload == nil ? nil : UIRefreshControl()
            self.refreshControl?.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        }
    }

    var callback: AnyObject -> () = { _ in () }
    var configureCell: (UITableViewCell, AnyObject) -> UITableViewCell = { $0.0 }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : UITableViewCell = UITableViewCell(style: cellStyle, reuseIdentifier: nil) // todo dequeue
        var obj: AnyObject = items![indexPath.row]
        return configureCell(cell, obj)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var obj: AnyObject = items![indexPath.row]
        callback(obj)
    }

    func refresh(sender: UIRefreshControl?) {
        reload? { [weak self] items in
            self?.items = items
            sender?.endRefreshing()
        }
    }
}
