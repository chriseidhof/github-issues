//
//  TableView.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 28/02/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import UIKit

func tableViewController<A>(configuration: TableViewConfiguration<A>) -> [A] -> Screen<A> {
    return { items in
        return asyncTableVC({ $0(items) }, configuration)
    }
}

func standardCell<A>(f: A -> String) -> TableViewConfiguration<A> {
    var config: TableViewConfiguration<A> = TableViewConfiguration()
    config.render = { cell, a in
        cell.textLabel?.text = f(a)
    }
    return config
}

private func twoTextCell<A>(style: UITableViewCellStyle)(_ f: A -> (title: String, subtitle: String)) -> TableViewConfiguration<A> {
    return TableViewConfiguration(render: { (cell: UITableViewCell, a: A) in
        let (title, subtitle) = f(a)
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle
        }, style: style)
}

func value1Cell<A>(f: A -> (title: String, subtitle: String)) -> TableViewConfiguration<A> {
    return twoTextCell(.Value1)(f)
}

func subtitleCell<A>(f: A -> (title: String, subtitle: String)) -> TableViewConfiguration<A> {
    return twoTextCell(.Subtitle)(f)
}

func value2Cell<A>(f: A -> (title: String, subtitle: String)) -> TableViewConfiguration<A> {
    return twoTextCell(.Value2)(f)
}

struct TableViewConfiguration<A> {
    var render: (UITableViewCell, A) -> () = { _ in }
    var style: UITableViewCellStyle = UITableViewCellStyle.Default
}

enum BarButtonTitle {
    case Text(String)
    case SystemItem(UIBarButtonSystemItem)
}

struct BarButton {
    let title: BarButtonTitle
    let callback: () -> ()
}

struct NavigationItem {
    var title: String?
    var rightBarButtonItem: BarButton?

    init(title: String? = nil, rightBarButtonItem: BarButton? = nil) {
        self.title = title
        self.rightBarButtonItem = rightBarButtonItem
    }
}

let defaultNavigationItem = NavigationItem(title: nil, rightBarButtonItem: nil)

func asyncTableVC<A>(loadData: ([A] -> ()) -> (), configuration: TableViewConfiguration<A>, navigationItem: NavigationItem = defaultNavigationItem) -> Screen<A> {
    return Screen { callback in
        var myTableViewController = MyViewController(style: UITableViewStyle.Plain)
        loadData { (items: [A]) in
            myTableViewController.items = items.map { Box($0) }
            return ()
        }
        myTableViewController.cellStyle = configuration.style
        myTableViewController.items = nil // items.map { Box($0) }
        myTableViewController.configureCell = { cell, obj in
            if let boxed = obj as? Box<A> {
                configuration.render(cell, boxed.unbox)
            }
            return cell
        }
        myTableViewController.applyNavigationItem(navigationItem)
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

var AssociatedObjectHandle: UInt8 = 0

@objc class CompletionHandler: NSObject {
    let handler: () -> ()
    init(_ handler: () -> ()) {
        self.handler = handler
    }

    @objc func tapped(sender: UIBarButtonItem) {
        self.handler()
    }
}

extension UIViewController {
    var rightBarButtonCompletion: CompletionHandler? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectHandle) as? CompletionHandler
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectHandle, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }

    func applyNavigationItem(navigationItem: NavigationItem) {
        self.navigationItem.title = navigationItem.title
        if let barButton = navigationItem.rightBarButtonItem {
            self.rightBarButtonCompletion = CompletionHandler(barButton.callback)
            switch barButton.title {
            case .Text(let title):
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: title, style: UIBarButtonItemStyle.Plain, target: self.rightBarButtonCompletion, action: "tapped:")
            case .SystemItem(let systemItem):
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: systemItem, target: self.rightBarButtonCompletion, action: "tapped:")
            }

        }
    }
}

class MyViewController: UITableViewController {
    var cellStyle: UITableViewCellStyle = .Default
    var items: NSArray? = [] {
        didSet {
            self.view.backgroundColor = items == nil ? UIColor.grayColor() : UIColor.whiteColor()
            self.tableView.reloadData()
        }
    }
    var callback: AnyObject -> () = { _ in () }
    var configureCell: (UITableViewCell, AnyObject) -> UITableViewCell = { $0.0 }
    
    override func viewDidLoad() {
        println("load")
    }
    
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
}
