//
//  DSL.swift
//  FactoryGirlSwift
//
//  Created by Kevin Barrett on 6/15/14.
//  Copyright (c) 2014 Little Spindle, LLC. All rights reserved.
//

import Foundation

// DSL calls operate on a global FactoryGirl instance
let globalFactoryGirl: FactoryGirl = FactoryGirl()

// We use trampoline objects to bounce setters to factories,
// define some closures to make building the trampolines easier.
typealias DSLDefinition = (FactoryTrampoline) -> ()
typealias DSLArrayDefinition = (Int, FactoryTrampoline) -> ()

// DEFINERS

/// Defines a factory with the given name. The base argument defines an auto-closure that should create
/// the object the factory will build upon. The definition closure provides an opportunity to set
/// properties on the factory using string subscript syntax.
func define(factoryName: String, base: @auto_closure () -> FactoryBuildable, definition: DSLDefinition) {
    globalFactoryGirl.define(factoryName, baseObject: base) { factory in
        FactoryTrampoline.defineAndApply(definition, toFactory: factory)
    }
}

//// SETTERS

func theFactory(factoryName: String, instanceDefinition: DSLDefinition? = nil) -> ValueSetterTrampoline {
    return ValueSetterTrampoline(factoryName: factoryName, instanceDefinition)
}

extension Int {
    func ofFactory(factoryName: String, definitions: DSLArrayDefinition? = nil) -> ValueSetterTrampoline {
        return ValueSetterTrampoline(factoryName: factoryName, count: self, instanceDefinitions: definitions)
    }
}

//// BUILDERS

func build(factoryName: String, instanceDefinition: DSLDefinition? = nil ) -> FactoryBuildable? {
    return globalFactoryGirl.build(factoryName) { factory in
        if let definition = instanceDefinition {
            FactoryTrampoline.defineAndApply(definition, toFactory: factory)
        }
    }
}



class FactoryTrampoline {
    var valueSetters: Dictionary<String, ValueSetterTrampoline> = [:]
    var subfactoryDefintions: Dictionary<String, (FactoryTrampoline) -> ()> = [:]
    
    class func defineAndApply(definition: DSLDefinition, toFactory: Factory) {
        let trampoline = FactoryTrampoline()
        definition(trampoline)
        trampoline.apply(toFactory)
    }
    
    class func defineAndApplyArray(definition: DSLArrayDefinition, atIndex: Int, toFactory: Factory) {
        let trampoline = FactoryTrampoline()
        definition(atIndex, trampoline)
        trampoline.apply(toFactory)
    }
    
    func define(factoryName: String, definition: (FactoryTrampoline) -> ()) {
        subfactoryDefintions[factoryName] = definition
    }
    
    subscript(key: String) -> AnyObject? {
        get {
            return valueSetters[key]
        }
        set {
            if let value: AnyObject = newValue {
                valueSetters[key] = ValueSetterTrampoline.trampolineForSome(value)
            }
            else {
                valueSetters[key] = nil
            }
            
        }
    }
    
    func apply(toFactory: Factory) {
        _applySettersToFactory(toFactory);
        _buildSubfactoriesOfFactory(toFactory);
    }
    
    func _applySettersToFactory(factory: Factory) {
        for (key, setter) in valueSetters {
            setter.apply(key, factory)
        }
    }
    
    func _buildSubfactoriesOfFactory(factory: Factory) {
        for (factoryName, definition) in subfactoryDefintions {
            factory.define(factoryName) { subfactory in
                FactoryTrampoline.defineAndApply(definition, toFactory: subfactory)
            }
        }
    }
}

class ValueSetterTrampoline {
    let apply: (String, Factory) -> ()
    
    class func trampolineForSome(thing: AnyObject) -> ValueSetterTrampoline {
        if let alreadyASetter = thing as? ValueSetterTrampoline {
            return alreadyASetter
        }
        else {
            return ValueSetterTrampoline(object: thing)
        }
    }
    
    init(object: AnyObject) {
        apply = { key, factory in
            println("Applying \(key) with value \(object.description)")
            factory.set(key, withValue: object)
        }
    }
    
    init(factoryName: String, instanceDefinition: DSLDefinition?) {
        apply = { key, factory in
            println("Applying \(key) with factory \(factoryName)")
            if let definition = instanceDefinition {
                factory.set(key, withFactoryNamed: factoryName) { factory in
                    FactoryTrampoline.defineAndApply(definition, toFactory: factory)
                }
            }
            else {
                factory.set(key, withFactoryNamed: factoryName)
            }
        }
    }
    
    init(factoryName: String, count: Int, instanceDefinitions: DSLArrayDefinition?) {
        apply = { key, factory in
            println("Applying \(key) with factory \(factoryName) \(count) times")
            if let definitions = instanceDefinitions {
                factory.set(key, withCollectionOfFactoriesNamed: factoryName, count: count) { i, factory in
                    FactoryTrampoline.defineAndApplyArray(definitions, atIndex: i, toFactory: factory)
                }
            }
            else {
                factory.set(key, withCollectionOfFactoriesNamed: factoryName, count: count)
            }
        }
    }
}