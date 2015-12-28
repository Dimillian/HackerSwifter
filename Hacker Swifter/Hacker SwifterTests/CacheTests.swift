//
//  CacheTests.swift
//  HackerSwifter
//
//  Created by Thomas Ricouard on 16/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import XCTest
import HackerSwifter

class CacheTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    func pathtest() {
        let path = "test/test?test/test"
        let result = "test#test?test#test"
        
        XCTAssertTrue(DiskCache.generateCacheKey(path) == result, "cache key is not equal to result")
    }
    
    func testMemoryCache() {
        let post = Item()
        post.title = "Test"
        
        MemoryCache.sharedMemoryCache.setObject(post, key: "post")
        
        let postTest = MemoryCache.sharedMemoryCache.objectForKeySync("post") as! Item
    
        XCTAssertNotNil(postTest, "Post is nil")
        XCTAssertTrue(postTest.isKindOfClass(Item), "Post is not kind of class post")
        XCTAssertTrue(postTest.title == "Test", "Post title is not equal to prior test")
        
        MemoryCache.sharedMemoryCache.removeObject("post")
        
        XCTAssertNil(MemoryCache.sharedMemoryCache.objectForKeySync("post"), "post should be nil")
    }
    
    func testDiskCache() {
        let post = Item()
        post.title = "Test"
        
        DiskCache.sharedDiskCache.setObject(post, key: "post")
        
        let postTest = DiskCache.sharedDiskCache.objectForKeySync("post") as! Item
        
        XCTAssertNotNil(postTest, "Post is nil")
        XCTAssertTrue(postTest.isKindOfClass(Item), "Post is not kind of class post")
        XCTAssertTrue(postTest.title == "Test", "Post title is not equal to prior test")
        
        DiskCache.sharedDiskCache.removeObject("post")
        
        XCTAssertNil(DiskCache.sharedDiskCache.objectForKeySync("post"), "post should be nil")
    }
    
    func testGlobalCache() {
        let post = Item()
        post.title = "Global Test"
        
        Cache.sharedCache.setObject(post, key: "post")
        
        let globalPost = Cache.sharedCache.objectForKeySync("post") as! Item
        let memoryPost = MemoryCache.sharedMemoryCache.objectForKeySync("post") as! Item
        let diskPost = DiskCache.sharedDiskCache.objectForKeySync("post") as! Item
        
        XCTAssertNotNil(globalPost, "Global Post is nil")
        XCTAssertNotNil(memoryPost, "Memory Post is nil")
        XCTAssertNotNil(diskPost, "Dissk Post is nil")
        
        XCTAssertTrue(globalPost.isKindOfClass(Item), "Global Post is not kind of class post")
        XCTAssertTrue(globalPost.title == "Global Test", "Global Post title is not equal to prior test")
        
        XCTAssertTrue(memoryPost.isKindOfClass(Item), "Memory Post is not kind of class post")
        XCTAssertTrue(memoryPost.title == "Global Test", "Memory Post title is not equal to prior test")
        
        XCTAssertTrue(diskPost.isKindOfClass(Item), "Disk Post is not kind of class post")
        XCTAssertTrue(diskPost.title == "Global Test", "Disk Post title is not equal to prior test")
        
        Cache.sharedCache.removeObject("post")
        
        XCTAssertNil(Cache.sharedCache.objectForKeySync("post"), "post should be nil")
        XCTAssertNil(MemoryCache.sharedMemoryCache.objectForKeySync("post"), "post should be nil")
        XCTAssertNil(DiskCache.sharedDiskCache.objectForKeySync("post"), "post should be nil")
    }
    
}
