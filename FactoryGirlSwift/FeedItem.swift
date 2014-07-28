//
//  FeedItem.swift
//  KTBFactoryGirlExample
//
//  Created by Kevin Barrett on 6/9/14.
//  Copyright (c) 2014 Little Spindle, LLC. All rights reserved.
//

import UIKit

public class FeedItem: NSObject {
    public init() {
        super.init()
    }
    public var itemID: NSNumber?
    public var userID: NSNumber?
    public var text: String?
    public var commentsCount = 0
    public var likesCount = 0
    public var URL: NSURL?
    public var deleted = false
    public var ordinal = 0
    override public var description: String {
        return "\n<FeedItem>\(itemID), \(text), \(commentsCount), \(likesCount), \(URL), \(deletedDescription)"
    }
    public var deletedDescription: String {
        return deleted ? "Deleted" : "Not deleted"
    }
}
