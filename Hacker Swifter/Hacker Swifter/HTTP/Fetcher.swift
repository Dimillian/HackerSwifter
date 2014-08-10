//
//  Fetcher.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation
import UIKit

private let _Fetcher = Fetcher()

public class Fetcher {

    internal let baseURL = "https://news.ycombinator.com/"
    internal let APIURL = "https://hn.algolia.io/api/v1/"
    private let session = NSURLSession.sharedSession()
  
    private let reachability: Reachability?
  
    
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
  
    init() {
        reachability = Reachability.reachabilityForInternetConnection()
        reachability!.startNotifier()
    }
  
    private func hostReachable() -> Bool {
        return (_Fetcher.reachability!.currentReachabilityStatus() == NetworkStatus.ReachableViaWiFi || _Fetcher.reachability!.currentReachabilityStatus() == NetworkStatus.ReachableViaWWAN)
    }
    
    class func Fetch(ressource: String, parsing: FetchParsing, completion: FetchCompletion) {
    
        self.showLoadingIndicator(true)
        
        var cacheKey = Cache.generateCacheKey(ressource)
        if (_Fetcher.hostReachable()) {
            var path = _Fetcher.baseURL + ressource
            var task = _Fetcher.session.dataTaskWithURL(NSURL(string: path) , completionHandler: {(data: NSData!, response, error: NSError!) in
                if !error {
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
                }
                else {
                    completion(object: nil, error: ResponseError.UnknownError, local: false)
                }
            })
            task.resume()
        } else {
            Cache.sharedCache.objectForKey(cacheKey, completion: {(object: AnyObject!) in
                if var realObject: AnyObject = object {
                    completion(object: realObject, error: nil, local: true)
                }
            })
        }
    }
  
    //In the future, all scraping will be removed and we'll use only the Algolia API
    //At the moment this function is sufixed for testing purpose
    class func FetchAPI(ressource: String, parsing: FetchParsingAPI, completion: FetchCompletion) {
        var path = _Fetcher.APIURL + ressource
        var task = _Fetcher.session.dataTaskWithURL(NSURL(string: path) , completionHandler: {(data: NSData!, response, error: NSError!) in
            if var data = data {
                var error: NSError? = nil
                var JSON: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &error)
                if error != nil {
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