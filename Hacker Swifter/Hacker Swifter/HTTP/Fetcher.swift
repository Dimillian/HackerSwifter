//
//  Fetcher.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

let _Fetcher = Fetcher()

class Fetcher {

    let baseURL = "https://news.ycombinator.com/"
    let session = NSURLSession.sharedSession()
    
    typealias FetchCompletion = (String!, ResponseError!) -> Void
    
    enum ResponseError: String {
        case NoConnection = "You are not connected to the internet"
        case ErrorParsing = "An error occurred while fetching the requested page"
    }
    
    class var sharedInstance: Fetcher {
        return _Fetcher
    }
    
    class func Fetch(ressource: String, completion: FetchCompletion) {
        var path = _Fetcher.baseURL + ressource
        var task = _Fetcher.session.dataTaskWithURL(NSURL(string: path) , completionHandler: {(data: NSData!, response, error: NSError!) in
            if let realData = data {
                completion(NSString(data: realData, encoding: NSUTF8StringEncoding), nil)
            }
            else {
                completion(nil, ResponseError.ErrorParsing)
            }
        })
    }
}