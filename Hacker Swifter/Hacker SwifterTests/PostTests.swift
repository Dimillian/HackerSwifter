//
//  Post.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import UIKit
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

    func testFetchNews() {
        var expectation = self.expectationWithDescription("fetch posts")
        
        Post.fetch(.Top, completion: {(posts: [Post]!, error: Fetcher.ResponseError!, local: Bool) in            
            if (!local) {
                XCTAssertTrue(posts!.count > 1, "posts should contain post")
                expectation.fulfill()
            }
        })
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testFetchPostForUser() {
        var expectation = self.expectationWithDescription("fetch posts")
        
        Post.fetch("dimillian", completion: {(posts: [Post]!, error: Fetcher.ResponseError!, local: Bool) in
            if (!local) {
                XCTAssertTrue(posts!.count > 1, "posts should contain post")
                expectation.fulfill()
            }
            })
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
