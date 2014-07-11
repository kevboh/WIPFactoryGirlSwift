//
//  FactoryBuilder.swift
//  FactoryGirlSwift
//
//  Created by Kevin Barrett on 7/11/14.
//  Copyright (c) 2014 Little Spindle, LLC. All rights reserved.
//

import Foundation
import CoreData

class FactoryBuilder {
    
    enum FactoryBuildStyle {
        case Object
        case Dictionary
        case ManagedObject
    }
    
    var buildStyle: FactoryBuildStyle = .Object
    var managedObjectContext: NSManagedObjectContext?
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