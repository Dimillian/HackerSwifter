//
//  Post.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

class Post {
    
    typealias Response = ([Post]!, Fetcher.ResponseError!) -> Void
    
    enum PostFilter: String {
        case Top = ""
        case Ask = "ask"
        case New = "newest"
        case Jobs = "jobs"
        case Best = "best"
    }
    
    class func fetch(filter: PostFilter, completion: Response) {
        Fetcher.Fetch(filter.toRaw(), completion: {(html) in
            completion(nil, nil)
        })
    }
}