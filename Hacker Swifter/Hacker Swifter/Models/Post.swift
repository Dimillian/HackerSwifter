//
//  Post.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

@objc(Post) public class Post: NSObject, NSCoding {

    public var title: String?
    public var username: String?
    public var url: NSURL?
    public var domain: String? {
        get {
            var host: NSString = self.url!.host
            if (host.hasPrefix("www")) {
                host = host.substringFromIndex(4)
            }
            return host
        }
    }
    public var points: Int?
    public var commentsCount: Int?
    public var postId: String?
    public var prettyTime: String?
    public var upvoteURL: String?
    public var type: PostFilter?

    public enum PostFilter: String {
        case Top = ""
        case Default = "default"
        case Ask = "ask"
        case New = "newest"
        case Jobs = "jobs"
        case Best = "best"
        case Show = "show"
    }
    
    private enum SerializationKey: String {
        case title = "title"
        case username = "username"
        case url = "url"
        case points = "points"
        case commentsCount = "commentsCount"
        case postId = "postId"
        case prettyTime = "time"
        case upvoteURL = "upvoteURL"
        case type = "type"
        
        static let allValues = [title, username, url, points, commentsCount, postId, prettyTime, upvoteURL, type]
    }

    public init(){
        super.init()
    }
    
    public init(html: String) {
        super.init()
        self.parseHTML(html)
    }
    
    public init(coder aDecoder: NSCoder!) {
        super.init()
        for key in SerializationKey.allValues {
            setValue(aDecoder.decodeObjectForKey(key.toRaw()), forKey: key.toRaw())
        }
    }
    
    public func encodeWithCoder(aCoder: NSCoder!) {
        
        for key in SerializationKey.allValues {
            if let value: AnyObject = self.valueForKey(key.toRaw()) {
                aCoder.encodeObject(value, forKey: key.toRaw())
            }
        }
}
}

//Network
public extension Post {
    
    public typealias Response = (posts: [Post]!, error: Fetcher.ResponseError!, local: Bool) -> Void
    public typealias ResponsePost = (post: Post!, error: Fetcher.ResponseError!, local: Bool) -> Void
    
    public class func fetch(filter: PostFilter, completion: Response) {
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
    
    public class func fetch(user: String, completion: Response) {
        Fetcher.Fetch("submitted?id=" + user, parsing: {(html) in
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
    
    //Test using Algolia API For later
    public class func fetchPostDetailAPI(post: String, completion: ResponsePost) {
        var path = "items/" + post
        Fetcher.FetchAPI(path, parsing: {(json) in
            return json
        },
        completion: {(object, error, local) in
            completion(post: nil, error: error, local: local)
        })
    }
}

//HTML
internal extension Post {
    
    internal class func parseCollectionHTML(html: String) -> [Post] {
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
    
    internal func parseHTML(html: String) {
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
