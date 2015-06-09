//
//  UIViewController+Extensions.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 07/03/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import UIKit

@objc class CompletionHandler: NSObject {
    let handler: BarButtonContext -> ()
    weak var viewController: UIViewController?
    init(_ handler: BarButtonContext -> (), _ viewController: UIViewController) {
        self.handler = handler
        self.viewController = viewController
    }

    @objc func tapped(sender: UIBarButtonItem) {
        let context = BarButtonContext(button: sender, viewController: viewController!)
        self.handler(context)
    }
}

public enum BarButtonTitle {
    case Text(String)
    case SystemItem(UIBarButtonSystemItem)
}

public struct BarButtonContext {
    public let button: UIBarButtonItem
    public let viewController: UIViewController
}

public struct BarButton {
    public let title: BarButtonTitle
    public let callback: BarButtonContext -> ()
    public init(title: BarButtonTitle, callback: BarButtonContext -> ()) {
        self.title = title
        self.callback = callback
    }
}

public let defaultNavigationItem = NavigationItem(title: nil, rightBarButtonItem: nil)


public struct NavigationItem {
    public var title: String?
    public var rightBarButtonItem: BarButton?
    public var leftBarButtonItem: BarButton?

    public init(title: String? = nil, rightBarButtonItem: BarButton? = nil, leftBarButtonItem: BarButton? = nil) {
        self.title = title
        self.rightBarButtonItem = rightBarButtonItem
        self.leftBarButtonItem = leftBarButtonItem
    }
}

extension BarButton {
    func barButtonItem(completionHandler: CompletionHandler) -> UIBarButtonItem {
        switch title {
        case .Text(let title):
            return UIBarButtonItem(title: title, style: UIBarButtonItemStyle.Plain, target: completionHandler, action: "tapped:")
        case .SystemItem(let systemItem):
            return UIBarButtonItem(barButtonSystemItem: systemItem, target: completionHandler, action: "tapped:")
        }
    }
}

var AssociatedRightCompletionHandle: UInt8 = 0
var AssociatedLeftCompletionHandle: UInt8 = 0

extension UIViewController {
    // todo this should be on the bar button...
    var rightBarButtonCompletion: CompletionHandler? {
        get {
            return objc_getAssociatedObject(self, &AssociatedRightCompletionHandle) as? CompletionHandler
        }
        set {
            objc_setAssociatedObject(self, &AssociatedRightCompletionHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var leftBarButtonCompletion: CompletionHandler? {
        get {
            return objc_getAssociatedObject(self, &AssociatedLeftCompletionHandle) as? CompletionHandler
        }
        set {
            objc_setAssociatedObject(self, &AssociatedLeftCompletionHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func setRightBarButton(barButton: BarButton) {
        let completion = CompletionHandler(barButton.callback, self)
        self.rightBarButtonCompletion = completion
        self.navigationItem.rightBarButtonItem = barButton.barButtonItem(completion)
    }

    func setLeftBarButton(barButton: BarButton) {
        let completion = CompletionHandler(barButton.callback, self)
        self.leftBarButtonCompletion = completion
        self.navigationItem.leftBarButtonItem = barButton.barButtonItem(completion)
    }



    func applyNavigationItem(navigationItem: NavigationItem) {
        self.navigationItem.title = navigationItem.title
        if let barButton = navigationItem.rightBarButtonItem {
            setRightBarButton(barButton)
        }
        if let barButton = navigationItem.leftBarButtonItem {
            setLeftBarButton(barButton)
        }
    }

}