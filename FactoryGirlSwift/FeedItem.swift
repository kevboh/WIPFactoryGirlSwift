//
//  FeedItem.swift
//  KTBFactoryGirlExample
//
//  Created by Kevin Barrett on 6/9/14.
//  Copyright (c) 2014 Little Spindle, LLC. All rights reserved.
//

import UIKit

class FeedItem: NSObject {
    var itemID: NSNumber?
    var userID: NSNumber?
    var text: String?
    var commentsCount = 0
    var likesCount = 0
    var URL: NSURL?
    var deleted = false
    var ordinal = 0
    override var description: String {
        return "\n<FeedItem>\(itemID), \(text), \(commentsCount), \(likesCount), \(URL), \(deletedDescription)"
    }
    var deletedDescription: String {
        return deleted ? "Deleted" : "Not deleted"
    }
}
