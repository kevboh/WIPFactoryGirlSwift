//
//  DSLTests.swift
//  FactoryGirlSwift
//
//  Created by Kevin Barrett on 7/18/14.
//  Copyright (c) 2014 Little Spindle, LLC. All rights reserved.
//

import UIKit
import XCTest
import FactoryGirlSwift

class DSLTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDSL() {
        
        define("Feed", Feed()) { feed in
            feed["title"] = "My Title"
            feed["firstItem"] = theFactory("FeedItem")
            feed["lastItem"] = theFactory("FeedItem") { feedItem in
                feedItem["text"] = "My last item"
            }
            
            feed["items"] = 10.ofFactory("FeedItem") { index, feedItem in
                feedItem["itemID"] = index
            }
            
            feed.define("Other Feed") { otherFeed in
                otherFeed["title"] = "My Other Title"
            }
        }
        
        define("FeedItem", FeedItem()) { feedItem in
            feedItem["text"] = "My item text"
        }
        
        let feed = build("Feed") as Feed
        XCTAssertEqual(feed.title!, "My Title", "Titles should match")
        XCTAssertEqual(feed.firstItem!.text!, "My item text", "Item text should match")
        XCTAssertEqual(feed.lastItem!.text!, "My last item", "Item text should match")
        XCTAssertEqual(feed.items!.count, 10, "Feed should have 10 items")
        for i in 0..<10 {
            XCTAssertEqual(feed.items![i].itemID as Int, i, "Item IDs should match indices")
        }
        
        let otherFeed = build("Other Feed") as Feed
        XCTAssertEqual(otherFeed.title!, "My Other Title", "Titles should match")
    }

}
