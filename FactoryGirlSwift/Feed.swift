//
//  Feed.swift
//  KTBFactoryGirlExample
//
//  Created by Kevin Barrett on 6/9/14.
//  Copyright (c) 2014 Little Spindle, LLC. All rights reserved.
//

import UIKit

class Feed: NSObject {
    var title: String?
    var timestamp: NSDate?
    var userID: NSNumber?
    var items: [FeedItem]?
    var firstItem: FeedItem?
    var lastItem: FeedItem?
    override var description: String {
        return "\nFeed titled \(title) for user \(userID) at \(timestamp), items: \(items)"
    }
}
