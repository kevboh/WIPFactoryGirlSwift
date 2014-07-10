//
//  Post.swift
//  FactoryGirlSwift
//
//  Created by Kevin Barrett on 6/15/14.
//  Copyright (c) 2014 Little Spindle, LLC. All rights reserved.
//

import UIKit
import CoreData

class Post: NSManagedObject {
    @NSManaged var text: String
    @NSManaged var timestamp: NSDate
    @NSManaged var title: String
    
    override func awakeFromInsert() {
        timestamp = NSDate.date()
    }
}
