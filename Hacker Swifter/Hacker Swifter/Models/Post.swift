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
    var domain: String? {
        get {
            var host: NSString = self.url!.host
            if (host.hasPrefix("www")) {
                host = host.substringFromIndex(4)
            }
            return host
        }
    }
    var points: Int?
    var commentsCount: Int?
    var postId: String?
    var prettyTime: String?
    var upvoteURL: String?
    var type: PostFilter?

    enum PostFilter: String {
        case Top = ""
        case Default = "default"
        case Ask = "ask"
        case New = "newest"
        case Jobs = "jobs"
        case Best = "best"
        case Show = "show"
    }
    
    struct SerializationKey {
        static let title = "title"
        static let username = "username"
        static let url = "url"
        static let points = "points"
        static let commentsCount = "commentsCount"
        static let postId = "postId"
        static let prettyTime = "time"
        static let upvoteURL = "upvoteURL"
        static let type = "type"
    }

    init(){
        super.init()
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
        aCoder.encodeObject(self.points, forKey: SerializationKey.points)
        aCoder.encodeObject(self.commentsCount, forKey: SerializationKey.commentsCount)
        aCoder.encodeObject(self.prettyTime, forKey: SerializationKey.prettyTime)
        aCoder.encodeObject(self.postId, forKey: SerializationKey.postId)
        aCoder.encodeObject(self.upvoteURL, forKey: SerializationKey.upvoteURL)
    }
    
}

//Network
extension Post {
    
    typealias Response = (posts: [Post]!, error: Fetcher.ResponseError!, local: Bool) -> Void
    
    class func fetch(filter: PostFilter, completion: Response) {
        Fetcher.Fetch(filter.toRaw(),
            parsing: {(html) in
                if let realHtml = html {
                    var posts = self.parseCollectionHTML(realHtml)
                    return posts
                }
                else {
                    return nil
                }
            },
            completion: {(object, error, local) in
                completion(posts: object as [Post], error: error, local: local)
            })
    }
}

//HTML
extension Post {
    
    class func parseCollectionHTML(html: String) -> [Post] {
        var components = html.componentsSeparatedByString("<tr><td align=\"right\" valign=\"top\" class=\"title\">")
        var posts: [Post] = []
        if (components.count > 0) {
            var index = 0
            for component in components {
                if index != 0 {
                    var post = Post()
                    post.parseHTML(component)
                    posts.append(post)
                }
                index++
            }
        }
        return posts
    }
    
    func parseHTML(html: String) {
        var scanner = NSScanner(string: html)
        if !html.rangeOfString("<td class=\"title\"> [dead] <a") {
            
            self.url = NSURL(string: scanner.scanTag("<a href=\"", endTag: "\""))
            self.title = scanner.scanTag(">", endTag: "</a>")
            
            var temp: NSString = scanner.scanTag("<span id=\"score_", endTag: "</span>")
            var range = temp.rangeOfString(">")
            if (range.location != NSNotFound) {
                self.points = temp.substringFromIndex(range.location + 1).bridgeToObjectiveC().integerValue
            }
            
            self.username = scanner.scanTag("<a href=\"user?id=", endTag: "\"")
            self.prettyTime = scanner.scanTag("</a> ", endTag: "ago") + "ago"
            self.postId = scanner.scanTag("<a href=\"item?id=", endTag: "\">")
            
            temp = scanner.scanTag("\">", endTag: "</a>")
            if (temp == "discuss") {
                self.commentsCount = 0
            }
            else {
                self.commentsCount = temp.integerValue
            }
            
            if (!self.username && !self.commentsCount && !self.postId) {
                self.type = PostFilter.Jobs
            }
            else if (self.url?.absoluteString.bridgeToObjectiveC().rangeOfString("http").location == NSNotFound) {
                self.type = PostFilter.Ask
                var url = self.url?.absoluteString
                self.url = NSURL(string: "https://news.ycombinator.com/" + url!)
            }
            else {
                self.type = PostFilter.Default
            }
        }
    }
}
