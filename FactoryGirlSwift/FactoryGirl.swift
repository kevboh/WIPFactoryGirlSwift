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

import UIKit
import CoreData

// Declare a common protocol so non-NSObject class types can be created with factories
// TODO: change back to @class_protocol; see https://devforums.apple.com/thread/230764?
@objc protocol FactoryBuildable {
    // Just standard KVO
    func setValue(value: AnyObject!, forKey key: String!)
}
// Foundation.NSKeyValueCoding already implements this for NSObject, so declare conformance here.
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
    var objectBuilder: ObjectBuilder!
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
    
    func set(propertyName: String, withFactoryNamed factoryName: String) {
        valueDefinitions[propertyName] = FactoryValueDefinition(factoryName: factoryName)
    }
    
    func set(propertyName: String, withFactoryNamed factoryName: String, instanceDefinition: InstanceDefinition) {
        valueDefinitions[propertyName] = FactoryValueDefinition(factoryName: factoryName, instanceDefinition: instanceDefinition)
    }
    
    func set(propertyName: String, withCollectionOfFactoriesNamed factoryName: String, count: Int, instanceDefinitions: CollectionInstanceDefinition?) {
        let collectionSetter: (FactoryGirl.FactoryBuilder) -> AnyObject = { builder in
            // Must be an NSMutableArray since arrays are structs in swift
            var collection: NSMutableArray = []
            for i in 0..count {
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
    
    func _makeBaseObject(style: FactoryGirl.FactoryBuilder.FactoryBuildStyle, _ managedObjectContext: NSManagedObjectContext?) -> FactoryBuildable {
        switch style {
        case .Object:
            return objectBuilder()
        case .ManagedObject:
            return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as NSManagedObject
        case .Dictionary:
            return NSMutableDictionary.dictionary()
        }
    }
    
    func _buildable(style: FactoryGirl.FactoryBuilder.FactoryBuildStyle) -> Bool {
        switch style {
        case .Object:
            return objectBuilder != nil
        case .ManagedObject:
            return entityName != nil
        case .Dictionary:
            return true
        }
    }
    
    class FactoryValueDefinition {
        // The valueSetter actually generates the value, using a builder to maintain external build state (e.g. sequences)
        let valueSetter: (FactoryGirl.FactoryBuilder) -> AnyObject
        
        init(valueSetter: (FactoryGirl.FactoryBuilder) -> AnyObject) {
            self.valueSetter = valueSetter
        }
        
        // Closure setter: return the result of a closure
        convenience init(externalSetter: () -> AnyObject) { self.init(valueSetter: { builder in externalSetter() }) }
        
        // Factory setter: return something built from another factory
        convenience init(factoryName: String) {
            self.init(factoryName: factoryName, instanceDefinition: nil)
        }
        
        // Full factory setter: return something built from another factory, with a custom instance definition
        convenience init(factoryName: String, instanceDefinition: InstanceDefinition?) {
            let setter: (FactoryGirl.FactoryBuilder) -> AnyObject = { builder in
                return builder._buildFromFactory(factoryName, alteredDefinition: instanceDefinition)!
            }
            self.init(valueSetter: setter)
        }
        
        func makeValue(builder: FactoryGirl.FactoryBuilder) -> AnyObject {
            return valueSetter(builder)
        }
    }
}

class FactoryGirl {
    
    class FactoryBuilder {
        
        enum FactoryBuildStyle {
            case Object
            case Dictionary
            case ManagedObject
        }
        
        let buildStyle: FactoryBuildStyle = .Object
        let managedObjectContext: NSManagedObjectContext?
        let definedFactories: Dictionary<String, Factory>
        
        init(factories: Dictionary<String, Factory>) {
            self.definedFactories = factories
        }
        
        convenience init(style: FactoryBuildStyle, factories: Dictionary<String, Factory>) {
            self.init(factories: factories)
            self.buildStyle = style
        }
        
        convenience init(managedObjectContext: NSManagedObjectContext, factories: Dictionary<String, Factory>) {
            self.init(factories: factories)
            self.buildStyle = .ManagedObject
            self.managedObjectContext = managedObjectContext
        }
        
        func build(factoryName: String, alteredDefinition: Factory.InstanceDefinition?) -> FactoryBuildable? {
            let obj = _buildFromFactory(factoryName, alteredDefinition: alteredDefinition)
            cleanUp()
            return obj
        }
        
        // Reserved for FactoryGirl--calling these methods externally may result in unexpected values on built objects.
        
        func _buildFromFactory(factoryName: String, alteredDefinition: Factory.InstanceDefinition?) -> FactoryBuildable? {
            if var factory = definedFactories[factoryName] {
                if let definition = alteredDefinition {
                    factory = factory.copy()
                    definition(factory)
                }
                
                assert(factory._buildable(buildStyle), "You must set an object builder or entity name on a factory before it can build.")
                let objectToBuild = factory._makeBaseObject(buildStyle, managedObjectContext)
                return _buildObject(objectToBuild, fromFactory: factory)
            }
            return nil
        }
        
        func _buildObject(object: FactoryBuildable, fromFactory factory: Factory) -> FactoryBuildable? {
            // TODO factory hierarchy, object stacks
            
            var currentFactory: Factory? = factory
            while let f = currentFactory {
                _setAttributesOnBuildObject(object, fromFactory: f)
                currentFactory = f.superFactory
            }
            
            return object
        }
        
        func _setAttributesOnBuildObject(object: FactoryBuildable, fromFactory: Factory) {
            for (propertyName, valueDefinition) in fromFactory.valueDefinitions {
                let value: AnyObject = valueDefinition.makeValue(self)
//                println("Setting \(propertyName) to \(value)")
                object.setValue(value, forKey: propertyName)
            }
        }

        func cleanUp() {
            // TODO
        }
    }
    
    typealias FactoriesDefinition = (FactoryGirl) -> ()
    
    var factoriesByName: Dictionary<String, Factory> = [:]
    
    init (definitions: FactoriesDefinition) {
        definitions(self)
    }
    
    func define(factoryName: String, baseObject: @auto_closure () -> FactoryBuildable, definition: Factory.TemplateDefinition) {
        _define(factoryName, nil, baseObject, definition)
    }
    
    func define(factoryName: String, entityName: String, definition: Factory.TemplateDefinition) {
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
    
    func undefine(factoryName: String) {
        factoriesByName.removeValueForKey(factoryName)
    }
    
    func undefineAll() {
        factoriesByName.removeAll(keepCapacity: false)
    }
    
    func build(factoryName: String) -> FactoryBuildable? {
        return build(factoryName, alteredDefintion: nil)
    }
    
    func insert(factoryName: String, intoManagedObjectContext: NSManagedObjectContext, alteredDefintion: Factory.InstanceDefinition?) -> FactoryBuildable? {
        let builder = FactoryBuilder(managedObjectContext: intoManagedObjectContext, factories: factoriesByName)
        return builder.build(factoryName, alteredDefinition: alteredDefintion)
    }
    
    func build(factoryName: String, alteredDefintion: Factory.InstanceDefinition?) -> FactoryBuildable? {
        let builder = FactoryBuilder(factories: factoriesByName)
        return builder.build(factoryName, alteredDefinition: alteredDefintion)
    }
}