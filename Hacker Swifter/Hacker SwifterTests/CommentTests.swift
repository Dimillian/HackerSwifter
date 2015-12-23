//
//  CommentTests.swift
//  HackerSwifter
//
//  Created by Tosin Afolabi on 17/07/2014.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import UIKit
import XCTest
import HackerSwifter

class CommentTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFetchComments() {
        var expectation = self.expectationWithDescription("fetch comments for post")

        var post = Post()
        post.postId = "8255637"
        post.type = Post.PostFilter.Default

        Comment.fetch(forPost: post, completion: {(comments: [Comment]!, error: Fetcher.ResponseError!, local: Bool) in

            if (!local) {
                XCTAssertTrue(comments!.count > 0, "comments should not be empty")
                expectation.fulfill()
            }
            })

        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testAskHNComments() {
        var expectation = self.expectationWithDescription("fetch comments for post")
        
        var post = Post()
        post.postId = "8044029"
        post.type = Post.PostFilter.Ask
        
        Comment.fetch(forPost: post, completion: {(comments: [Comment]!, error: Fetcher.ResponseError!, local: Bool) in
            
            if (!local) {
                XCTAssertTrue(comments!.count > 0, "comments should not be empty")
                var comment = comments[0]
                XCTAssertTrue(comment.type == Comment.CommentFilter.Ask, "comment type is not good")
                XCTAssertTrue(count(comment.text!) > 0, "Comment content should not be empty")
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
