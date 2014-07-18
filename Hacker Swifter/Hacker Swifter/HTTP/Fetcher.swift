//
//  Fetcher.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation
import UIKit

let _Fetcher = Fetcher()

class Fetcher {

    let baseURL = "https://news.ycombinator.com/"
    let session = NSURLSession.sharedSession()
    
    typealias FetchCompletion = (object: AnyObject!, error: ResponseError!, local: Bool) -> Void
    typealias FetchParsing = (html: String!) -> AnyObject!
    
    enum ResponseError: String {
        case NoConnection = "You are not connected to the internet"
        case ErrorParsing = "An error occurred while fetching the requested page"
        case UnknownError = "An unknown error occurred"
    }
    
    class var sharedInstance: Fetcher {
        return _Fetcher
    }
    
    class func Fetch(ressource: String, parsing: FetchParsing, completion: FetchCompletion) {
        
        if let application = UIApplication.sharedApplication() {
            application.networkActivityIndicatorVisible = true
        }
        
        var cacheKey = Cache.generateCacheKey(ressource)
        
        Cache.sharedCache.objectForKey(cacheKey, completion: {(object: AnyObject!) in
            if var realObject: AnyObject = object {
                completion(object: realObject, error: nil, local: true)
            }
        })
        
        var path = _Fetcher.baseURL + ressource
        var task = _Fetcher.session.dataTaskWithURL(NSURL(string: path) , completionHandler: {(data: NSData!, response, error: NSError!) in
            
            if let realData = data {
                var object: AnyObject! = parsing(html: NSString(data: realData, encoding: NSUTF8StringEncoding))
                if var realObject: AnyObject = object {
                    Cache.sharedCache.setObject(realObject, key: cacheKey)
                }
                dispatch_async(dispatch_get_main_queue(), { ()->() in
                    if let application = UIApplication.sharedApplication() {
                        application.networkActivityIndicatorVisible = true
                    }
                    completion(object: object, error: nil, local: false)
                })
            }
            else {
                dispatch_async(dispatch_get_main_queue(), { ()->() in
                    if let application = UIApplication.sharedApplication() {
                        application.networkActivityIndicatorVisible = true
                    }
                    completion(object: nil, error: ResponseError.UnknownError, local: false)
                })
            }
        })
        task.resume()
    }
}