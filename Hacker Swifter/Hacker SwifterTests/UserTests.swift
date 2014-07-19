//
//  UserTests.swift
//  HackerSwifter
//
//  Created by Tosin Afolabi on 18/07/2014.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import UIKit
import XCTest
import HackerSwifter

class UserTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFetchUserProfile() {
        var expectation = self.expectationWithDescription("fetch user profile")
        let username = "toisnaf"

        User.fetch(forUser: username, completion: {(user: User!, error: Fetcher.ResponseError!, local: Bool) in
            println(user.username)
            if (!local) {
                XCTAssertTrue(true, "posts should contain post")
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
