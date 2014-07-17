//
//  Cache.swift
//  HackerSwifter
//
//  Created by Thomas Ricouard on 16/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

let _Cache = Cache()
let _MemoryCache = MemoryCache()
let _DiskCache = DiskCache()

typealias cacheCompletion = (AnyObject!) -> Void

class Cache {

    class var sharedCache: Cache {
        return _Cache
    }
    
    init() {
        
    }
    
    class func generateCacheKey(path: String) -> String {
        if (path == "") {
            return "root"
        }
        return path.stringByReplacingOccurrencesOfString("/",
            withString: "#", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
    }
    
    func setObject(object: AnyObject, key: String) {
        if (object.conformsToProtocol(NSCoding)) {
            MemoryCache.sharedMemoryCache.setObject(object, key: key)
            DiskCache.sharedDiskCache.setObject(object, key: key)
        }
    }
    
    func objectForKey(key: String, completion: cacheCompletion) {
        MemoryCache.sharedMemoryCache.objectForKey(key, completion: {(object: AnyObject!) in
            if let realObject: AnyObject = object {
                completion(realObject)
            }
            else {
                DiskCache.sharedDiskCache.objectForKey(key, completion: {(object: AnyObject!) in
                    completion(object)
                })
            }
        })
    }
    
    func objectForKeySync(key: String) -> AnyObject! {
        var ramObject: AnyObject! = MemoryCache.sharedMemoryCache.objectForKeySync(key)
        return ramObject ? ramObject : DiskCache.sharedDiskCache.objectForKeySync(key)
    }
    
    func removeObject(key: String) {
        MemoryCache.sharedMemoryCache.removeObject(key)
        DiskCache.sharedDiskCache.removeObject(key)
    }
    
    func removeAllObject() {
        MemoryCache.sharedMemoryCache.removeAllObject()
        DiskCache.sharedDiskCache.removeAllObject()
    }
}

class DiskCache: Cache {
    
    struct files {
        static var filepath: String {
            var manager = NSFileManager.defaultManager()
            var paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory,
                NSSearchPathDomainMask.UserDomainMask, true)
            var cachePath = paths[0] as String + "/modelCache/"
                if (!manager.fileExistsAtPath(cachePath)) {
                    manager.createDirectoryAtPath(cachePath, withIntermediateDirectories: true, attributes: nil, error: nil)
                }
            return cachePath
        }
    }
    
    let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT

    class var sharedDiskCache: Cache {
        return _DiskCache
    }

    init() {

    }
    
    func fullPath(key: String) -> String {
        return files.filepath + key
    }
    
    func objectExist(key: String) -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(fullPath(key))
    }
    
    override func objectForKey(key: String, completion: cacheCompletion) {
        if (self.objectExist(key)) {
            dispatch_async(dispatch_get_global_queue(self.priority, UInt(0)), { ()->() in
                var object: AnyObject! =  NSKeyedUnarchiver.unarchiveObjectWithFile(self.fullPath(key))
                dispatch_async(dispatch_get_main_queue(), { ()->() in
                    completion(object)
                    })
                })
        }
        else {
            completion(nil)
        }
    }
    
    override func objectForKeySync(key: String) -> AnyObject! {
        if (self.objectExist(key)) {
            return NSKeyedUnarchiver.unarchiveObjectWithFile(self.fullPath(key))
        }
        return nil
    }
    
    override func setObject(object: AnyObject, key: String) {
        NSKeyedArchiver.archiveRootObject(object, toFile: self.fullPath(key))
    }
    
    override func removeObject(key: String) {
        if (self.objectExist(key)) {
            NSFileManager.defaultManager().removeItemAtPath(self.fullPath(key), error: nil)
        }
    }
    
    override func removeAllObject() {

    }
}

class MemoryCache: Cache {
    
    var memoryCache = NSCache()
    
    class var sharedMemoryCache: Cache {
        return _MemoryCache
    }
    
    init() {
        
    }
    
    override func objectForKeySync(key: String) -> AnyObject! {
        return self.memoryCache.objectForKey(key)
    }
    
    override func objectForKey(key: String, completion: cacheCompletion)  {
        completion(self.memoryCache.objectForKey(key))
    }
    
    override func setObject(object: AnyObject, key: String) {
        self.memoryCache.setObject(object, forKey: key)
    }
    
    override func removeObject(key: String) {
        self.memoryCache.removeObjectForKey(key)
    }
    
    override func removeAllObject() {
        self.memoryCache.removeAllObjects()
    }
    
}
