//
//  User.swift
//  FactoryGirlSwift
//
//  Created by Kevin Barrett on 6/15/14.
//  Copyright (c) 2014 Little Spindle, LLC. All rights reserved.
//

import UIKit
import CoreData

class User: NSManagedObject {
    @NSManaged var email: String
    @NSManaged var name: String
    @NSManaged var serverID: Int
    
    override var description: String {
        return "User named \(name) with email \(email) and ID \(serverID)"
    }
}
