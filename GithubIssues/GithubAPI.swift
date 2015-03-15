//
//  GithubAPI.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 28/02/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import FunctionalViewControllers

public struct User {
    public let login: String
    public let avatarURL: NSURL?
}

public struct Repository {
    public let name: String
    public let owner: User
    public let description_: String
    public let url: NSURL
}

public struct Organization {
    public let login: String
    public let reposURL: NSURL
}

public enum IssueState: String {
    case Open = "open"
    case Closed = "closed"
}

public struct Issue {
    public let state: IssueState
    public let title: String
    public let body: String?
    public let assignee: User?
    public let creator: User
    public let milestone: Milestone?
}

public struct Milestone {
    public let title: String
    
    static func parse(input: AnyObject) -> Milestone? {
        if let dict = input as? JSONDictionary,
            title = input["title"] as? String
        {
            return Milestone(title: title)
        }
        return nil
    }
}


extension Repository {
    static func parse(input: AnyObject) -> Repository? {
        if let dict = input as? JSONDictionary,
            name = dict["name"] as? String,
            owner = User.parse(dict["owner"]),
            description = dict["description"] as? String,
            urlString = dict["html_url"] as? String,
            url = NSURL(string: urlString)
        {
            return Repository(name: name, owner: owner, description_: description, url: url)
        }
        return nil
        
    }
    
    var issuesResource: Resource<[Issue]> {
        return jsonResource(issuesPath, .GET, [:], array(Issue.parse))
    }

    var issuesPath: String {
        return path + "/issues"
    }

    var path: String {
        return "/repos/\(owner.login)/\(name)"
    }

    func createIssueResource(title: String, body: String) -> Resource<Issue> {
        let path = issuesPath
        let dict: JSONDictionary = ["title": title as NSString, "body": body as NSString]
        return jsonResource(path, Method.POST, dict, Issue.parse)
    }
}

extension Organization {
    static func parse(input: AnyObject) -> Organization? {
        if let dict = input as? JSONDictionary,
            name = dict["login"] as? String,
            reposURLString = dict["repos_url"] as? String,
            reposURL = NSURL(string: reposURLString)
        {
            return Organization(login: name, reposURL: reposURL)
        }
        return nil
        
    }
    
    var reposResource: Resource<[Repository]> {
        return jsonResource(reposURL.path!, .GET, [:], array(Repository.parse))
    }
}

extension User {
    static func parse(input: AnyObject?) -> User? {
        if let dict = input as? JSONDictionary,
           login = dict["login"] as? String,
           urlString = dict["avatar_url"] as? String
        {
            return User(login: login, avatarURL: NSURL(string: urlString))
        }
        return nil
    }
}

extension Issue {
    static func parse(input: AnyObject?) -> Issue? {
        if let dict = input as? JSONDictionary,
               title = dict["title"] as? String,
               stateString = dict["state"] as? String,
               state = IssueState(rawValue: stateString),
            creator = User.parse(dict["user"])
        {
            let assignee = User.parse(dict["assignee"])
            let body = dict["body"] as? String
            var milestone: Milestone? = nil
            if let milestoneObj: AnyObject = dict["milestone"]
            {
                milestone = Milestone.parse(milestoneObj)
            }
            return Issue(state: state, title: title, body: body, assignee: assignee, creator: creator, milestone: milestone)
        }
        return nil
    }
}

public func repositories(user: String?) -> Resource<[Repository]> {
    let path: String
    if let username = user {
        path = "/users/\(username)/repos"
    } else {
        path = "/user/repos"
    }
    return jsonResource(path, .GET, [:], array(Repository.parse))
}

public func star(repository: Repository) -> Resource<()> {
    let path = "/users/starred/\(repository.owner.login)/\(repository.name)"
    return Resource(path: path, method: .PUT, requestBody: nil, headers: [:], parse: { _ in
        ()
    })
}

public func organizations() -> Resource<[Organization]> {
    return jsonResource("/user/orgs", .GET, [:], array(Organization.parse))
}

func array<A>(element: AnyObject -> A?)(input: AnyObject) -> [A]? {
    if let theArray = input as? [AnyObject] {
        var result: [A?] = theArray.map(element)
        if result.filter({ $0 == nil }).count == 0 {
            return result.map { $0! }
        }
    }
    return nil
}

let baseURL = NSURL(string: "https://api.github.com")!

func addToken(r: NSMutableURLRequest) {
    r.setValue("token \(githubToken)", forHTTPHeaderField: "Authorization")
}

func request<A>(resource: Resource<A>, completion: A? -> ()) -> () {
    apiRequest(addToken, baseURL, resource, { (reason, data) -> () in
        if let theData = data, str = NSString(data: theData, encoding: NSUTF8StringEncoding) {
            println(str)
        }
        println("Reason: \(reason)")
        completion(nil)
        }, { progress in
            ()
        }, { success in completion(success)})
}
