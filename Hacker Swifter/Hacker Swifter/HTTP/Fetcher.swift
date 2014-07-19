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
    let APIURL = "https://hn.algolia.io/api/v1/"
    let session = NSURLSession.sharedSession()
    
    typealias FetchCompletion = (object: AnyObject!, error: ResponseError!, local: Bool) -> Void
    typealias FetchParsing = (html: String!) -> AnyObject!
    typealias FetchParsingAPI = (json: AnyObject) -> AnyObject!
    
    enum ResponseError: String {
        case NoConnection = "You are not connected to the internet"
        case ErrorParsing = "An error occurred while fetching the requested page"
        case UnknownError = "An unknown error occurred"
    }
    
    class var sharedInstance: Fetcher {
        return _Fetcher
    }
    
    class func Fetch(resource: String, parsing: FetchParsing, completion: FetchCompletion) {
    
        self.showLoadingIndicator(true)
        
        var cacheKey = Cache.generateCacheKey(resource)
        Cache.sharedCache.objectForKey(cacheKey, completion: {(object: AnyObject!) in
            if var realObject: AnyObject = object {
                completion(object: realObject, error: nil, local: true)
            }
        })
        
        var path = _Fetcher.baseURL + resource
        var task = _Fetcher.session.dataTaskWithURL(NSURL(string: path) , completionHandler: {(data: NSData!, response, error: NSError!) in
            
            if let realData = data {
                var object: AnyObject! = parsing(html: NSString(data: realData, encoding: NSUTF8StringEncoding))
                if var realObject: AnyObject = object {
                    Cache.sharedCache.setObject(realObject, key: cacheKey)
                }
                dispatch_async(dispatch_get_main_queue(), { ()->() in
                    self.showLoadingIndicator(false)
                    completion(object: object, error: nil, local: false)
                })
            }
            else {
                dispatch_async(dispatch_get_main_queue(), { ()->() in
                    self.showLoadingIndicator(false)
                    completion(object: nil, error: ResponseError.UnknownError, local: false)
                })
            }
        })
        task.resume()
    }
    
    //In the future, all scraping will be removed and we'll use only the Algolia API
    //At the moment this function is sufixed for testing purpose
    class func FetchAPI(resource: String, parsing: FetchParsingAPI, completion: FetchCompletion) {
        var path = _Fetcher.APIURL + resource
        var task = _Fetcher.session.dataTaskWithURL(NSURL(string: path) , completionHandler: {(data: NSData!, response, error: NSError!) in
            if var data = data {
                var error: NSError? = nil
                var JSON: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &error)
                if !error {
                    var object: AnyObject! = parsing(json: JSON)
                    if var object: AnyObject = object {
                        completion(object: object, error: nil, local: false)
                    }
                    else {
                        completion(object: nil, error: ResponseError.ErrorParsing, local: false)
                    }
                }
                else {
                    completion(object: nil, error: ResponseError.UnknownError, local: false)
                }
            }
        })
        task.resume()
    }
    
    class func showLoadingIndicator(show: Bool) {
        if let application = UIApplication.sharedApplication() {
            application.networkActivityIndicatorVisible = show
        }
    }
    
}