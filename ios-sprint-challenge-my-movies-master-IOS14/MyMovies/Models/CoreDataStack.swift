//
//  CoreDataStack.swift
//  MyMovies
//
//  Created by Ufuk Türközü on 28.02.20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation
import CoreData

import CoreData

class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    private init() {
        
    }
    
    lazy var container: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "Movie")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error {
                fatalError("Error loading Persistent Stores: \(error)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }() // Creating only one instance for use
    
    var mainContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    func save(context: NSManagedObjectContext = CoreDataStack.shared.mainContext) throws {
        
        var error: Error?
        context.performAndWait {
            do {
                try context.save()
            } catch let saveError {
                error = saveError
                NSLog("Error saving context \(String(describing: error))")
                // mainContext.reset()
            }
        }
        
        if error != nil {
            throw error!
        }
    }
}

