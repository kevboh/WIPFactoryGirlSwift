//
//  FactoryGirl.swift
//  Pods
//
//  Created by Kevin Barrett on 6/10/14.
//
//

/*
Restrictions:
1. Built objects must conform to the FactoryBuildable protocol, which is just an abstraction for KVO.
   Subclasses of NSObject conform to FactoryBuildable by default. Custom classes must explicitly conform.
2. Currently the FactoryBuildable protocol is a @class_protocol, so only class types may be built.
   I want to figure out a way around this, but KVO enforces AnyObject! as the value for setting,
   and in order for a FactoryBuildable to be set via KVO it appears it must be a @class_protocol.
   !! Submit pull requests if you find a workaround, please!
   2a. Actually currently @objc due to Swift bug, see https://devforums.apple.com/thread/230764?
3. Each Factory requires an objectBuilder closure that instantiates a base object, because I haven't
   figured out how to store classes and instantiate them at runtime like I did in ObjC.
   !! Submit pull requests if you find a workaround, please!
*/

// TODO: DSL using custom operators?
// TODO: parent object relationships
// TODO: lazy closure values

import UIKit
import CoreData


public class FactoryGirl {
    
    public typealias FactoriesDefinition = (FactoryGirl) -> ()
    
    var factoriesByName: Dictionary<String, Factory> = [:]
    
    public convenience init (definitions: FactoriesDefinition) {
        self.init()
        definitions(self)
    }
    
    public func define(factoryName: String, baseObject: @auto_closure () -> FactoryBuildable, definition: Factory.TemplateDefinition) {
        _define(factoryName, nil, baseObject, definition)
    }
    
    public func define(factoryName: String, entityName: String, definition: Factory.TemplateDefinition) {
        _define(factoryName, entityName, nil, definition)
    }
    
    func _define(factoryName: String, _ possibleEntityName: String?, _ possibleObjectBuilder: (() -> FactoryBuildable)?, _ definition: Factory.TemplateDefinition) {
        let factory = Factory(name: factoryName)
        // Set entity name if core data
        if let entityName = possibleEntityName {
            factory.entityName = entityName
        }
        // Set builder if not core data
        if let objectBuilder = possibleObjectBuilder {
            factory.objectBuilder = objectBuilder
        }
        factory.owner = self
        definition(factory)
        factoriesByName[factory.name] = factory
    }
    
    public func undefine(factoryName: String) {
        factoriesByName.removeValueForKey(factoryName)
    }
    
    public func undefineAll() {
        factoriesByName.removeAll(keepCapacity: false)
    }
    
    public func build(factoryName: String) -> FactoryBuildable? {
        return build(factoryName, alteredDefintion: nil)
    }
    
    public func insert(factoryName: String, intoManagedObjectContext: NSManagedObjectContext, alteredDefintion: Factory.InstanceDefinition?) -> FactoryBuildable? {
        let builder = FactoryBuilder(managedObjectContext: intoManagedObjectContext, factories: factoriesByName)
        return builder.build(factoryName, alteredDefinition: alteredDefintion)
    }
    
    public func build(factoryName: String, alteredDefintion: Factory.InstanceDefinition?) -> FactoryBuildable? {
        let builder = FactoryBuilder(factories: factoriesByName)
        return builder.build(factoryName, alteredDefinition: alteredDefintion)
    }
}