//
//  FactoryBuildable.swift
//  FactoryGirlSwift
//
//  Created by Kevin Barrett on 7/11/14.
//  Copyright (c) 2014 Little Spindle, LLC. All rights reserved.
//

import Foundation

// Declare a common protocol so non-NSObject class types can be created with factories
// TODO: change back to @class_protocol; see https://devforums.apple.com/thread/230764?
@objc public protocol FactoryBuildable {
    // Just standard KVO
    func setValue(value: AnyObject!, forKey key: String!)
}
// Foundation.NSKeyValueCoding already implements this for NSObject, so declare conformance here.
extension NSObject: FactoryBuildable {}