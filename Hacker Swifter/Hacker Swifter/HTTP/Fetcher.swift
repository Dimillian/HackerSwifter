//
//  Fetcher.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

private let _Fetcher = Fetcher()

open class Fetcher {

    internal let baseURL = "https://news.ycombinator.com/"
    internal let APIURL = "https://hacker-news.firebaseio.com/v0/"
    internal let APIFormat = ".json"
    fileprivate let session = URLSession.shared
    
    public typealias FetchCompletion = (_ object: AnyObject?, _ error: ResponseError?, _ local: Bool) -> Void
    public typealias FetchParsing = (_ html: String?) -> AnyObject!
    public typealias FetchParsingAPI = (_ json: AnyObject) -> AnyObject!
    
    public enum ResponseError: String {
        case NoConnection = "You are not connected to the internet"
        case ErrorParsing = "An error occurred while fetching the requested page"
        case UnknownError = "An unknown error occurred"
    }
    
    public enum APIEndpoint: String {
        case Post = "item/"
        case User = "user/"
        case Top = "topstories"
        case New = "newstories"
        case Ask = "askstories"
        case Jobs = "jobstories"
        case Show = "showstories"
    }
    
    open class var sharedInstance: Fetcher {
        return _Fetcher
    }
    
    class func Fetch(_ ressource: String, parsing: @escaping FetchParsing, completion: @escaping FetchCompletion) {
    
        let cacheKey = Cache.generateCacheKey(ressource)
        Cache.sharedCache.objectForKey(cacheKey, completion: {(object: AnyObject!) in
            if let realObject: AnyObject = object {
                completion(realObject, nil, true)
            }
        })
        
        let path = _Fetcher.baseURL + ressource
        let task = _Fetcher.session.dataTask(with: URL(string: path)! , completionHandler: {(data: Data?, response, error: Error?) in
            if !(error != nil) {
                if let realData = data {
                    let object: AnyObject! = parsing(NSString(data: realData, encoding: String.Encoding.utf8.rawValue) as? String)
                    if let realObject: AnyObject = object {
                        Cache.sharedCache.setObject(realObject, key: cacheKey)
                    }
                    DispatchQueue.main.async(execute: { ()->() in
                        completion(object, nil, false)
                        })
                }
                else {
                    DispatchQueue.main.async(execute: { ()->() in
                        completion(nil, ResponseError.UnknownError, false)
                        })
                }
            }
            else {
                completion(nil, ResponseError.UnknownError, false)
            }
        })
        task.resume()
    }
    
    //In the future, all scraping will be removed and we'll use only the Algolia API
    //At the moment this function is sufixed for testing purpose
    class func FetchJSON(_ endpoint: APIEndpoint, ressource: String?, parsing: @escaping FetchParsingAPI, completion: @escaping FetchCompletion) {
        var path: String
        if let realRessource: String = ressource {
            path = _Fetcher.APIURL + endpoint.rawValue + realRessource + _Fetcher.APIFormat
        }
        else {
            path = _Fetcher.APIURL + endpoint.rawValue + _Fetcher.APIFormat
        }
        
        let cacheKey = Cache.generateCacheKey(path)
        Cache.sharedCache.objectForKey(cacheKey, completion: {(object: AnyObject!) in
            if let realObject: AnyObject = object {
                completion(realObject, nil, true)
            }
        })
        
        let task = _Fetcher.session.dataTask(with: URL(string: path)! , completionHandler: {(data: Data?, response, error: Error?) in
            if let data = data {
                var error: NSError? = nil
                var JSON: Any!
                do {
                    JSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                } catch let error1 as NSError {
                    error = error1
                    JSON = nil
                } catch {
                    fatalError()
                }
                if error == nil {
                    let object: AnyObject! = parsing(JSON as AnyObject)
                    if let object: AnyObject? = object {
                        if let realObject: AnyObject = object {
                            Cache.sharedCache.setObject(realObject, key: cacheKey)
                        }
                        DispatchQueue.main.async(execute: { ()->() in
                            completion(object, nil, false)
                        })

                    }
                    else {
                        DispatchQueue.main.async(execute: { ()->() in
                           completion(nil, ResponseError.ErrorParsing, false)
                        })

                    }
                }
                else {
                    completion(nil, ResponseError.UnknownError, false)
                }
            }
        })
        task.resume()
    }
    
}
