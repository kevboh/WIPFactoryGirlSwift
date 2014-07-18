//
//  Factory.swift
//  FactoryGirlSwift
//
//  Created by Kevin Barrett on 7/11/14.
//  Copyright (c) 2014 Little Spindle, LLC. All rights reserved.
//

import Foundation
import CoreData

extension NSObject: FactoryBuildable {}

class Factory {
    // An ObjectBuilder represents a closure that returns an instance of an object we can build on
    typealias ObjectBuilder = () -> FactoryBuildable
    // Template and Instance Definitions provide the closures in which we can define our factories
    // TemplateDefinitions are meant for initial definitions of factories,
    // InstanceDefinitions are meant for on-the-fly alterations at build time.
    typealias TemplateDefinition = (Factory) -> ()
    typealias InstanceDefinition = (Factory) -> ()
    // When defining a collection, the definition is also provided the index.
    typealias CollectionInstanceDefinition = (Int, Factory) -> ()
    
    let name: String
    var entityName: String?
    var objectBuilder: ObjectBuilder?
    var valueDefinitions: Dictionary<String, FactoryValueDefinition> = [:]
    weak var owner: FactoryGirl?
    weak var superFactory: Factory?
    
    init(name: String) {
        self.name = name
    }
    
    func copy() -> Factory {
        let factory = Factory(name: self.name)
        factory.objectBuilder = self.objectBuilder
        factory.valueDefinitions = self.valueDefinitions
        factory.owner = self.owner
        factory.superFactory = self.superFactory
        return factory
    }
    
    subscript(key: String) -> AnyObject? {
        get {
            assert(false, "Subscripts must have a getter, but getting a value definition is not supported at present.")
            return nil
        }
        set {
            if let value: AnyObject = newValue {
                set(key, withValue: value)
            }
            else {
                valueDefinitions.removeValueForKey(key)
            }
        }
    }
    
    func set(propertyName: String, withValue closure: @auto_closure () -> AnyObject) {
        valueDefinitions[propertyName] = FactoryValueDefinition(externalSetter: closure)
    }
    
    func set(propertyName: String, withFactoryNamed factoryName: String, instanceDefinition: InstanceDefinition? = nil) {
        valueDefinitions[propertyName] = FactoryValueDefinition(factoryName: factoryName, instanceDefinition: instanceDefinition)
    }
    
    func set(propertyName: String, withCollectionOfFactoriesNamed factoryName: String, count: Int, instanceDefinitions: CollectionInstanceDefinition? = nil) {
        let collectionSetter: (FactoryBuilder) -> AnyObject = { builder in
            // Must be an NSMutableArray since arrays are structs in swift
            var collection: NSMutableArray = []
            for i in 0..<count {
                var alteredDefinition: InstanceDefinition?
                if let perItemDefinition = instanceDefinitions {
                    alteredDefinition = { itemFactory in
                        perItemDefinition(i, itemFactory)
                    }
                }
                
                let possibleBuiltItem = builder._buildFromFactory(factoryName, alteredDefinition: alteredDefinition)
                if let builtItem = possibleBuiltItem {
                    collection.addObject(builtItem)
                }
            }
            
            return collection
        }
        
        valueDefinitions[propertyName] = FactoryValueDefinition(valueSetter: collectionSetter)
    }
    
    func define(factoryName: String, definition: TemplateDefinition) {
        if let owner = self.owner {
            owner._define(factoryName, nil, self.objectBuilder) { factory in
                // set superfactory here, then call definition
                factory.superFactory = self
                definition(factory)
            }
        }
    }
    
    func _makeBaseObject(style: FactoryBuildStyle, _ managedObjectContext: NSManagedObjectContext?) -> FactoryBuildable {
        switch style {
        case .Object:
            return objectBuilder!()
        case .ManagedObject:
            return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as NSManagedObject
        case .Dictionary:
            return NSMutableDictionary.dictionary()
        }
    }
    
    func _buildable(style: FactoryBuildStyle) -> Bool {
        switch style {
        case .Object:
            // TODO: fix workaround. See https://devforums.apple.com/message/1000640#1000640
            // In b3 optionals aren't directly testable against nil.
            // When fixing this, revert objectBuilder property to implicitly unwrapped optional.
            return objectBuilder.getLogicValue() != nil
        case .ManagedObject:
            return entityName != nil
        case .Dictionary:
            return true
        }
    }
    
    class FactoryValueDefinition {
        // The valueSetter actually generates the value, using a builder to maintain external build state (e.g. sequences)
        let valueSetter: (FactoryBuilder) -> AnyObject
        
        init(valueSetter: (FactoryBuilder) -> AnyObject) {
            self.valueSetter = valueSetter
        }
        
        // Closure setter: return the result of a closure
        convenience init(externalSetter: () -> AnyObject) { self.init(valueSetter: { builder in externalSetter() }) }
        
        // Full factory setter: return something built from another factory, with a custom instance definition
        convenience init(factoryName: String, instanceDefinition: InstanceDefinition? = nil) {
            let setter: (FactoryBuilder) -> AnyObject = { builder in
                return builder._buildFromFactory(factoryName, alteredDefinition: instanceDefinition)!
            }
            self.init(valueSetter: setter)
        }
        
        func makeValue(builder: FactoryBuilder) -> AnyObject {
            return valueSetter(builder)
        }
    }
}