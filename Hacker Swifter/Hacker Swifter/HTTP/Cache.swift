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

open class Cache {

    open class var sharedCache: Cache {
        return _Cache
    }
    
    init() {
        
    }
    
    open class func generateCacheKey(_ path: String) -> String {
        if (path == "") {
            return "root"
        }
        return path.replacingOccurrences(of: "/",
            with: "#", options: NSString.CompareOptions.caseInsensitive, range: nil)
    }
    
    open func setObject(_ object: AnyObject, key: String) {
        if (object.conforms(to: NSCoding.self)) {
            MemoryCache.sharedMemoryCache.setObject(object, key: key)
            DiskCache.sharedDiskCache.setObject(object, key: key)
        }
    }
    
    open func objectForKey(_ key: String, completion: cacheCompletion) {
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
    
    open func objectForKeySync(_ key: String) -> AnyObject! {
        let ramObject: AnyObject! = MemoryCache.sharedMemoryCache.objectForKeySync(key)
        return (ramObject != nil) ? ramObject : DiskCache.sharedDiskCache.objectForKeySync(key)
    }
    
    open func removeObject(_ key: String) {
        MemoryCache.sharedMemoryCache.removeObject(key)
        DiskCache.sharedDiskCache.removeObject(key)
    }
    
    open func removeAllObject() {
        MemoryCache.sharedMemoryCache.removeAllObject()
        DiskCache.sharedDiskCache.removeAllObject()
    }
}

open class DiskCache: Cache {
    
    fileprivate struct files {
        static var filepath: String {
            let manager = FileManager.default
            var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory,
                FileManager.SearchPathDomainMask.userDomainMask, true)
            let cachePath = paths[0] + "/modelCache/"
                if (!manager.fileExists(atPath: cachePath)) {
                    do {
                        try manager.createDirectory(atPath: cachePath, withIntermediateDirectories: true, attributes: nil)
                    } catch _ {
                    }
                }
            return cachePath
        }
    }
    
    fileprivate let priority = DispatchQoS.QoSClass.default
    

    open class var sharedDiskCache: Cache {
        return _DiskCache
    }

    override init() {

    }
    
    open func fullPath(_ key: String) -> String {
        return files.filepath + key
    }
    
    open func objectExist(_ key: String) -> Bool {
        return FileManager.default.fileExists(atPath: fullPath(key))
    }
    
    open func objectForKey(_ key: String, completion: @escaping cacheCompletion) {
        if (self.objectExist(key)) {
            DispatchQueue.global(qos: self.priority).async(execute: { ()->() in
                let object: AnyObject! =  NSKeyedUnarchiver.unarchiveObject(withFile: self.fullPath(key)) as AnyObject!
                DispatchQueue.main.async(execute: { ()->() in
                    completion(object)
                    })
                })
        }
        else {
            completion(nil)
        }
    }
    
    open override func objectForKeySync(_ key: String) -> AnyObject! {
        if (self.objectExist(key)) {
            return NSKeyedUnarchiver.unarchiveObject(withFile: self.fullPath(key)) as AnyObject!
        }
        return nil
    }
    
   open override func setObject(_ object: AnyObject, key: String) {
        NSKeyedArchiver.archiveRootObject(object, toFile: self.fullPath(key))
    }
    
    open override func removeObject(_ key: String) {
        if (self.objectExist(key)) {
            do {
                try FileManager.default.removeItem(atPath: self.fullPath(key))
            } catch _ {
            }
        }
    }
    
    open override func removeAllObject() {

    }
}

open class MemoryCache: Cache {
    
    fileprivate var memoryCache = NSCache<AnyObject, AnyObject>()
    
    open class var sharedMemoryCache: Cache {
        return _MemoryCache
    }
    
    override init() {
        
    }
    
    open override func objectForKeySync(_ key: String) -> AnyObject! {
        return self.memoryCache.object(forKey: key as AnyObject)
    }
    
    open override func objectForKey(_ key: String, completion: cacheCompletion)  {
        completion(self.memoryCache.object(forKey: key as AnyObject))
    }
    
    open override func setObject(_ object: AnyObject, key: String) {
        self.memoryCache.setObject(object, forKey: key as AnyObject)
    }
    
    open override func removeObject(_ key: String) {
        self.memoryCache.removeObject(forKey: key as AnyObject)
    }
    
    open override func removeAllObject() {
        self.memoryCache.removeAllObjects()
    }
    
}
