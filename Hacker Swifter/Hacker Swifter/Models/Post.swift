//
//  Post.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

@objc(Post) class Post: NSObject, NSCoding {

    var title: String?
    var username: String?
    var url: NSURL?
    var domain: String?
    var points: Int?
    var commentsCount: Int?
    var postId: String?
    var prettyTime: String?
    var upvoteURL: String?

    enum PostFilter: String {
        case Top = ""
        case Ask = "ask"
        case New = "newest"
        case Jobs = "jobs"
        case Best = "best"
    }
    
    struct SerializationKey {
        static let title = "title"
        static let username = "username"
        static let url = "url"
        static let domain = "domain"
        static let points = "points"
        static let commentsCount = "commentsCount"
        static let postId = "postId"
        static let prettyTime = "time"
        static let upvoteURL = "upvoteURL"
    }

    init(html: String) {
        super.init()
        self.parseHTML(html)
    }
    
    // We might want to do a Mantle like thing with magic keys matching
    
    init(coder aDecoder: NSCoder!) {
        self.title = aDecoder.decodeObjectForKey(SerializationKey.title) as? String
        self.username = aDecoder.decodeObjectForKey(SerializationKey.username) as? String
        self.url = aDecoder.decodeObjectForKey(SerializationKey.url) as? NSURL
        self.domain = aDecoder.decodeObjectForKey(SerializationKey.domain) as? String
        self.points = aDecoder.decodeObjectForKey(SerializationKey.points) as? Int
        self.commentsCount = aDecoder.decodeObjectForKey(SerializationKey.commentsCount) as? Int
        self.postId = aDecoder.decodeObjectForKey(SerializationKey.postId) as? String
        self.prettyTime = aDecoder.decodeObjectForKey(SerializationKey.prettyTime) as? String
        self.upvoteURL = aDecoder.decodeObjectForKey(SerializationKey.upvoteURL) as? String
    }
    
    func encodeWithCoder(aCoder: NSCoder!) {
        aCoder.encodeObject(self.title, forKey: SerializationKey.title)
        aCoder.encodeObject(self.username, forKey: SerializationKey.username)
        aCoder.encodeObject(self.url, forKey: SerializationKey.url)
        aCoder.encodeObject(self.domain, forKey: SerializationKey.domain)
        aCoder.encodeObject(self.points, forKey: SerializationKey.points)
        aCoder.encodeObject(self.commentsCount, forKey: SerializationKey.commentsCount)
        aCoder.encodeObject(self.prettyTime, forKey: SerializationKey.prettyTime)
        aCoder.encodeObject(self.postId, forKey: SerializationKey.postId)
        aCoder.encodeObject(self.upvoteURL, forKey: SerializationKey.upvoteURL)
    }
    
}

//Network
extension Post {
    
    typealias Response = ([Post]!, Fetcher.ResponseError!) -> Void
    
    class func fetch(filter: PostFilter, completion: Response) {
        Fetcher.Fetch(filter.toRaw(), completion: {(html, error) in
            if !error {
                if let realHtml = html {
                    var posts = self.parseCollectionHTML(realHtml)
                    completion(posts, nil)
                }
                else {
                    completion(nil, Fetcher.ResponseError.UnknownError)
                }
            }
            else {
                completion(nil, error)
            }
        })
    }
}

//HTML
extension Post {
    
    class func parseCollectionHTML(html: String) -> [Post] {
        var components = html.componentsSeparatedByString("<tr><td align=\"right\" valign=\"top\" class=\"title\">")
        if (components.count > 0) {
            for component in components {
                var scanner = NSScanner(string: component)
                var title = scanner.scanTag(">", endTag: "</a>")
            }
        }
        return []
    }
    
    func parseHTML(html: String) {
        
    }
}
