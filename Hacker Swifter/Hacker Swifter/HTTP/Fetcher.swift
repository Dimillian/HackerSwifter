//
//  Fetcher.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

private let _Fetcher = Fetcher()

public class Fetcher {

    internal let baseURL = "https://news.ycombinator.com/"
    internal let APIURL = "https://hn.algolia.io/api/v1/"
    private let session = NSURLSession.sharedSession()
    
    public typealias FetchCompletion = (object: AnyObject!, error: ResponseError!, local: Bool) -> Void
    public typealias FetchParsing = (html: String!) -> AnyObject!
    public typealias FetchParsingAPI = (json: AnyObject) -> AnyObject!
    
    public enum ResponseError: String {
        case NoConnection = "You are not connected to the internet"
        case ErrorParsing = "An error occurred while fetching the requested page"
        case UnknownError = "An unknown error occurred"
    }
    
    public class var sharedInstance: Fetcher {
        return _Fetcher
    }
    
    class func Fetch(ressource: String, parsing: FetchParsing, completion: FetchCompletion) {
    
        let cacheKey = Cache.generateCacheKey(ressource)
        Cache.sharedCache.objectForKey(cacheKey, completion: {(object: AnyObject!) in
            if let realObject: AnyObject = object {
                completion(object: realObject, error: nil, local: true)
            }
        })
        
        let path = _Fetcher.baseURL + ressource
        let task = _Fetcher.session.dataTaskWithURL(NSURL(string: path)! , completionHandler: {(data: NSData?, response, error: NSError?) in
            if !(error != nil) {
                if let realData = data {
                    let object: AnyObject! = parsing(html: NSString(data: realData, encoding: NSUTF8StringEncoding) as! String)
                    if let realObject: AnyObject = object {
                        Cache.sharedCache.setObject(realObject, key: cacheKey)
                    }
                    dispatch_async(dispatch_get_main_queue(), { ()->() in
                        completion(object: object, error: nil, local: false)
                        })
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), { ()->() in
                        completion(object: nil, error: ResponseError.UnknownError, local: false)
                        })
                }
            }
            else {
                completion(object: nil, error: ResponseError.UnknownError, local: false)
            }
        })
        task.resume()
    }
    
    //In the future, all scraping will be removed and we'll use only the Algolia API
    //At the moment this function is sufixed for testing purpose
    class func FetchAPI(ressource: String, parsing: FetchParsingAPI, completion: FetchCompletion) {
        let path = _Fetcher.APIURL + ressource
        let task = _Fetcher.session.dataTaskWithURL(NSURL(string: path)! , completionHandler: {(data: NSData?, response, error: NSError?) in
            if let data = data {
                var error: NSError? = nil
                var JSON: AnyObject!
                do {
                    JSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                } catch let error1 as NSError {
                    error = error1
                    JSON = nil
                } catch {
                    fatalError()
                }
                if error != nil {
                    let object: AnyObject! = parsing(json: JSON)
                    if let object: AnyObject = object {
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
    
}