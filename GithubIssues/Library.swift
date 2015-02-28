//
//  ViewController.swift
//  FunctionalViewControllers
//
//  Created by Chris Eidhof on 03/09/14.
//  Copyright (c) 2014 Chris Eidhof. All rights reserved.
//

import UIKit

public class Box<T> {
    public let unbox: T
    public init(_ value: T) { self.unbox = value }
}

func select<A,B,C>(vc: ViewController<B,C>, f: A -> B) -> ViewController<A,C> {
    return ViewController { x, callback in
        return vc.create(f(x)) { y in
            callback(y)
        }
    }
}

func map<A,B,C>(vc: ViewController<A,B>, f: B -> C) -> ViewController<A,C> {
    return ViewController { x, callback in
        return vc.create(x) { y in
            callback(f(y))
        }
    }
}


func map<A,B,C>(vc: NavigationController<A,B>, f: B -> C) -> NavigationController<A,C> {
    return NavigationController { x, callback in
        return vc.create(x) { (y, nc) in
            callback(f(y), nc)
        }
    }
}

func mapAsync<A,B,C>(vc: NavigationController<A,B>, f: (B, C -> ()) -> ()) -> NavigationController<A,C> {
    return NavigationController { x, callback in
        return vc.create(x) { (y, nc) in
            f(y, { c in
                callback(c, nc)
            })
        }
    }
}

struct ViewController<A,B> {
    let create: (A,B -> ()) -> UIViewController
    
    init(_ create: (A,B -> ()) -> UIViewController) {
        self.create = create
    }
}

struct NavigationController<A,B> {
    let create: (A, (B, UINavigationController) -> ()) -> UINavigationController
}

func run<A,B>(nc: NavigationController<A,B>, initialValue: A, finish: B -> ()) -> UINavigationController {
    return nc.create(initialValue) { b, _ in
        finish(b)
    }
}

func rootViewController<A,B>(vc: ViewController<A,B>) -> NavigationController<A,B> {
    return NavigationController { initial, callback in
        let navController = UINavigationController()
        let rootController = vc.create(initial, { callback($0, navController) } )
        navController.viewControllers = [rootController]
        return navController
    }
}

infix operator >>> { associativity left }

func >>><A,B,C>(l: NavigationController<A,B>, r: ViewController<B,C>) -> NavigationController<A,C> {
    return NavigationController { x, callback in
        let nc = l.create(x, { b, nc in
            let rvc = r.create(b, { c in
                callback(c, nc)
            })
            nc.pushViewController(rvc, animated: true)
        })
        return nc
    }
}

func textViewController() -> ViewController<String, ()> {
    return ViewController { string, _ in
        var tv = TextViewController()
        tv.textView.text = string
        return tv
    }
}

class TextViewController: UIViewController {
    var textView: UITextView = {
        var tv = UITextView()
        tv.editable = false
        return tv
    }()
    
    override func viewDidLoad() {
        view.addSubview(textView)
        textView.frame = view.bounds
    }
}
