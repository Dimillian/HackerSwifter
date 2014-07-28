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
    
    func testFetchNewsPage2() {
        var expectation = self.expectationWithDescription("fetch posts")
        var postsPage1:[Post] = []
        var postsPage2:[Post] = []
                
        Post.fetch(.Top, page:1, completion: {(posts: [Post]!, error: Fetcher.ResponseError!, local: Bool) in
            if (!local) {
                postsPage1 = posts
                XCTAssertTrue(posts!.count > 1, "page 1 posts should contain post")
                Post.fetch(.Top, page:2, completion: {(posts: [Post]!, error: Fetcher.ResponseError!, local: Bool) in
                    if (!local) {
                        postsPage2 = posts
                        XCTAssertTrue(posts!.count > 1, "page 2 posts should contain post")
                        XCTAssertNotEqual(postsPage1[0], postsPage2[0], "page 1 and two have the same content")
                        XCTAssertNotEqual(postsPage1[1], postsPage2[1], "page 1 and two have the same content")
                        XCTAssertNotEqual(postsPage1[2], postsPage2[2], "page 1 and two have the same content")
                        expectation.fulfill()
                    }
                })
            }
        })
        self.waitForExpectationsWithTimeout(10.0, handler: nil)
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
    
    func testFetchPostDetailAPI() {
        var expectation = self.expectationWithDescription("fetch post")
        Post.fetchPostDetailAPI("8044029", completion: {(post: Post!, error: Fetcher.ResponseError!, local: Bool) in
            if (!local) {
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
