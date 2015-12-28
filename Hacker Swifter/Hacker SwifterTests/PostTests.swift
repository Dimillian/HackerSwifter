//
//  Post.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import XCTest
import HackerSwifter

class PostTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testFetchPosts() {
        let expectation = self.expectationWithDescription("fetch post")
        Item.fetchPost(.Top) { (posts, error, local) -> Void in
            if (!local) {
                XCTAssertTrue(posts.count > 1, "API response should countain Post")
                Item.fetchPost(posts[0], completion: { (post, error, local) -> Void in
                    XCTAssertTrue(post.title?.utf8.count > 0, "Title content should not be empty")
                    expectation.fulfill()
                })
            }
        }
        self.waitForExpectationsWithTimeout(10.0, handler: nil)
    }
}
