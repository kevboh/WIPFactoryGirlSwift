//
//  FactoryGirlSwiftTests.swift
//  FactoryGirlSwiftTests
//
//  Created by Kevin Barrett on 6/10/14.
//  Copyright (c) 2014 Little Spindle, LLC. All rights reserved.
//

import XCTest
import FactoryGirlSwift
import CoreData

class FactoryGirlSwiftTests: XCTestCase {
    
    class var factoryGirl: FactoryGirl {
        struct Static {
            
            static let instance: FactoryGirl = FactoryGirl() { factoryGirl in
                factoryGirl.define("Feed", baseObject: Feed()) { feed in
                    feed.set("title", withValue: "My Title")
                    feed.set("timestamp", withValue: NSDate.date())
                    feed.set("items", withCollectionOfFactoriesNamed: "DeletedFeedItem", count: 10) { i, factory in
                        factory.set("commentsCount", withValue: i)
                    }
                }
                
                factoryGirl.define("FeedItem", baseObject: FeedItem()) { feedItem in
                    feedItem.set("text", withValue: "My feed item text")
                    feedItem.define("DeletedFeedItem") { deletedFeedItem in
                        deletedFeedItem.set("deleted", withValue: true)
                    }
                }
            }
            
        }
        return Static.instance
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBasic() {
//        let feed = Feed()
//        feed.setValue(FeedItem(), forKey: "test")
        
        let feed = FactoryGirlSwiftTests.factoryGirl.build("Feed") { feedFactory in
            feedFactory.set("userID", withValue: 23)
        } as Feed
        
        println("--> \(feed)")
    }
    
    func testCoreData() {
        let coreDataGirl = FactoryGirl() { factoryGirl in
            factoryGirl.define("User", entityName: "User") { userFactory in
                userFactory["email"] = "kevin@littlespindle.com"
                userFactory["name"] = "Kevin"
                userFactory["serverID"] = 123
            }
        }
        
        let user = coreDataGirl.insert("User", intoManagedObjectContext: managedObjectContext, alteredDefintion: nil) as NSManagedObject
        println(user)
    }
    
    // Core Data stack
    
    // Returns the managed object context for the application.
    // If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
    var managedObjectContext: NSManagedObjectContext {
    if !_managedObjectContext {
        let coordinator = self.persistentStoreCoordinator
        if coordinator != nil {
            _managedObjectContext = NSManagedObjectContext()
            _managedObjectContext!.persistentStoreCoordinator = coordinator
        }
        }
        return _managedObjectContext!
    }
    var _managedObjectContext: NSManagedObjectContext? = nil
    
    // Returns the managed object model for the application.
    // If the model doesn't already exist, it is created from the application's model.
    var managedObjectModel: NSManagedObjectModel {
    if !_managedObjectModel {
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")
        _managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL)
        }
        return _managedObjectModel!
    }
    var _managedObjectModel: NSManagedObjectModel? = nil
    
    // Returns the persistent store coordinator for the application.
    // If the coordinator doesn't already exist, it is created and the application's store added to it.
    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
    if !_persistentStoreCoordinator {
        var error: NSError? = nil
        _persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        if _persistentStoreCoordinator!.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: &error) == nil {
            abort()
        }
        }
        return _persistentStoreCoordinator!
    }
    var _persistentStoreCoordinator: NSPersistentStoreCoordinator? = nil
}
