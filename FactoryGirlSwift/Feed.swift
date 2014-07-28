//
//  Feed.swift
//  KTBFactoryGirlExample
//
//  Created by Kevin Barrett on 6/9/14.
//  Copyright (c) 2014 Little Spindle, LLC. All rights reserved.
//

import UIKit

public class Feed: NSObject {
    public init() {
        super.init()
    }
    public var title: String?
    public var timestamp: NSDate?
    public var userID: NSNumber?
    public var items: [FeedItem]?
    public var firstItem: FeedItem?
    public var lastItem: FeedItem?
    override public var description: String {
        return "\nFeed titled \(title) for user \(userID) at \(timestamp), items: \(items)"
    }
}
