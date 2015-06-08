//
//  CoreDataStack.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 24/05/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import CoreData

public class CUser: NSManagedObject {
    @NSManaged var login: String
//    @NSManaged var avatarURL: NSURL?
}

public class CRepository: NSManagedObject {
    @NSManaged var organization: COrganization
    @NSManaged var name: String
    @NSManaged var owner: CUser
//    @NSManaged var description_: String
//    @NSManaged var url: NSURL
}

public class COrganization: NSManagedObject {
    @NSManaged var login: String
//    @NSManaged var reposURL: NSURL
    @NSManaged var repositories_: NSSet
    
    var repositories: [CRepository] {
        get {
            return repositories_.allObjects as! [CRepository]
        }
        set {
            repositories_ = NSSet(array: newValue)
        }
    }
}

extension COrganization {
    var repositoriesController: ResultsController<CRepository> {
        let fetchRequest = NSFetchRequest(entityName: CRepository.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "organization = %@", self)
        return ResultsController(context: self.managedObjectContext!, fetchRequest: fetchRequest)
    }
}

extension CRepository {
    var issuesController: ResultsController<CIssue> {
        let fetchRequest = NSFetchRequest(entityName: CIssue.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "repository = %@", self)
        return ResultsController(context: self.managedObjectContext!, fetchRequest: fetchRequest)
    }
}

public class CIssue: NSManagedObject {
    @NSManaged var state: String
    @NSManaged var title: String
    @NSManaged var body: String?
    @NSManaged var assignee: CUser?
    @NSManaged var creator: CUser
    @NSManaged var repository: CRepository
//    @NSManaged var milestone: CMilestone?
}

extension CUser : CoreDataObject {
    static var entityName: String { return "User" }
    static var sortDescriptors: [NSSortDescriptor] { return [] }
}

extension COrganization: CoreDataObject {
    static var entityName: String { return "Organization" }
    static var sortDescriptors: [NSSortDescriptor] { return [] }
}

extension CRepository: CoreDataObject {
    static var entityName: String { return "Repository" }
    static var sortDescriptors: [NSSortDescriptor] { return [] }
}

extension CIssue: CoreDataObject {
    static var entityName: String { return "Issue" }
    static var sortDescriptors: [NSSortDescriptor] { return [] }
}

func seed(context: NSManagedObjectContext) -> () {
    let objcio: COrganization = insert(context)
    objcio.login = "objcio"

    let website: CRepository = insert(context)
    website.organization = objcio
    website.name = "website"
    
    let articles: CRepository = insert(context)
    articles.name = "articles"
    objcio.repositories.append(articles)

}

func setupStack() -> NSManagedObjectContext {
    let modelURL = NSBundle.mainBundle().URLForResource("GithubIssues", withExtension: "momd")!
    let model = NSManagedObjectModel(contentsOfURL: modelURL)!
    let context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
    context.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    context.persistentStoreCoordinator?.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: nil)
    return context
}

class ResultsController<A: CoreDataObject> : NSObject {
    var changeCallback: ([A] -> ())? = nil

    private var fetchedResultsController: NSFetchedResultsController
    private var frcDelegate: FRCDelegate?

    convenience init(context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest(entityName: A.entityName)
        fetchRequest.sortDescriptors = A.sortDescriptors
        self.init(context: context, fetchRequest: fetchRequest)
    }

    init(context: NSManagedObjectContext, fetchRequest: NSFetchRequest) {
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    }

    private var fetchedObjects: [A] {
        if let objs = fetchedResultsController.fetchedObjects as? [A] {
            return objs
        }
        return []
    }

    func load() -> [A] {
        if fetchedResultsController.delegate == nil {
            frcDelegate = FRCDelegate(callback: { [unowned self] in
                self.changeCallback?(self.fetchedObjects)
            })
            fetchedResultsController.delegate = frcDelegate!
            fetchedResultsController.performFetch(nil)
        }
        return fetchedObjects
    }
}

private class FRCDelegate: NSObject, NSFetchedResultsControllerDelegate {
    var callback: () -> ()

    init(callback: () -> ()) {
        self.callback = callback
    }

    @objc func controllerWillChangeContent(controller: NSFetchedResultsController) {
    }

    @objc func controllerDidChangeContent(controller: NSFetchedResultsController) {
        callback()
    }

}


protocol CoreDataObject: AnyObject {
    static var entityName: String { get }
    static var sortDescriptors: [NSSortDescriptor] { get }
}

func insert<A : CoreDataObject>(context: NSManagedObjectContext) -> A {
    let n = A.entityName
    return NSEntityDescription.insertNewObjectForEntityForName(n, inManagedObjectContext: context) as! A
}

func results<A: CoreDataObject>(context: NSManagedObjectContext) -> [A] {
    let fetchRequest = NSFetchRequest(entityName: A.entityName)
    let results = context.executeFetchRequest(fetchRequest, error: nil)
    fetchRequest.sortDescriptors = A.sortDescriptors
    return results as! [A]
}
