//
//  Cache.swift
//  HackerSwifter
//
//  Created by Thomas Ricouard on 16/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

private let _Cache = Cache()
private let _MemoryCache = MemoryCache()
private let _DiskCache = DiskCache()

public typealias cacheCompletion = (AnyObject!) -> Void

public class Cache {

    public class var sharedCache: Cache {
        return _Cache
    }
    
    init() {
        
    }
    
    public class func generateCacheKey(path: String) -> String {
        if (path == "") {
            return "root"
        }
        return path.stringByReplacingOccurrencesOfString("/",
            withString: "#", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
    }
    
    public func setObject(object: AnyObject, key: String) {
        if (object.conformsToProtocol(NSCoding)) {
            MemoryCache.sharedMemoryCache.setObject(object, key: key)
            DiskCache.sharedDiskCache.setObject(object, key: key)
        }
    }
    
    public func objectForKey(key: String, completion: cacheCompletion) {
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
    
    public func objectForKeySync(key: String) -> AnyObject! {
        var ramObject: AnyObject! = MemoryCache.sharedMemoryCache.objectForKeySync(key)
        return ramObject ? ramObject : DiskCache.sharedDiskCache.objectForKeySync(key)
    }
    
    public func removeObject(key: String) {
        MemoryCache.sharedMemoryCache.removeObject(key)
        DiskCache.sharedDiskCache.removeObject(key)
    }
    
    public func removeAllObject() {
        MemoryCache.sharedMemoryCache.removeAllObject()
        DiskCache.sharedDiskCache.removeAllObject()
    }
}

public class DiskCache: Cache {
    
    private struct files {
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
    
    private let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT

    public class var sharedDiskCache: Cache {
        return _DiskCache
    }

    override init() {

    }
    
    public func fullPath(key: String) -> String {
        return files.filepath + key
    }
    
    public func objectExist(key: String) -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(fullPath(key))
    }
    
    public override func objectForKey(key: String, completion: cacheCompletion) {
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
    
    public override func objectForKeySync(key: String) -> AnyObject! {
        if (self.objectExist(key)) {
            return NSKeyedUnarchiver.unarchiveObjectWithFile(self.fullPath(key))
        }
        return nil
    }
    
    public override func setObject(object: AnyObject, key: String) {
        dispatch_async(dispatch_get_global_queue(self.priority, UInt(0)), {
            NSKeyedArchiver.archiveRootObject(object, toFile: self.fullPath(key))
            RETURN
        })
    }
    
    public override func removeObject(key: String) {
        if (self.objectExist(key)) {
            NSFileManager.defaultManager().removeItemAtPath(self.fullPath(key), error: nil)
        }
    }
    
    public override func removeAllObject() {

    }
}

public class MemoryCache: Cache {
    
    private var memoryCache = NSCache()
    
    public class var sharedMemoryCache: Cache {
        return _MemoryCache
    }
    
    override init() {
        
    }
    
    public override func objectForKeySync(key: String) -> AnyObject! {
        return self.memoryCache.objectForKey(key)
    }
    
    public override func objectForKey(key: String, completion: cacheCompletion)  {
        completion(self.memoryCache.objectForKey(key))
    }
    
    public override func setObject(object: AnyObject, key: String) {
        self.memoryCache.setObject(object, forKey: key)
    }
    
    public override func removeObject(key: String) {
        self.memoryCache.removeObjectForKey(key)
    }
    
    public override func removeAllObject() {
        self.memoryCache.removeAllObjects()
    }
    
}
