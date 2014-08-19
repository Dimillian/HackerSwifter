//
//  Post.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

@objc(Post) public class Post: NSObject, NSCoding, Equatable {
    
    public var title: String?
    public var username: String?
    public var url: NSURL?
    public var domain: String? {
        get {
            if let realUrl = self.url {
                if let host = realUrl.host {
                    if (host.hasPrefix("www")) {
                        return host.substringFromIndex(advance(host.startIndex, 4))
                    }
                    return host
                }
            }
            return ""
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
    
    private struct SerializationKey {
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
    
    public override init(){
        super.init()
    }
    
    public init(html: String) {
        super.init()
        self.parseHTML(html)
    }
    
    // We might want to do a Mantle like thing with magic keys matching
    required public init(coder aDecoder: NSCoder) {
        self.title = aDecoder.decodeObjectForKey(SerializationKey.title) as? String
        self.username = aDecoder.decodeObjectForKey(SerializationKey.username) as? String
        self.url = aDecoder.decodeObjectForKey(SerializationKey.url) as? NSURL
        self.points = aDecoder.decodeObjectForKey(SerializationKey.points) as? Int
        self.commentsCount = aDecoder.decodeObjectForKey(SerializationKey.commentsCount) as? Int
        self.postId = aDecoder.decodeObjectForKey(SerializationKey.postId) as? String
        self.prettyTime = aDecoder.decodeObjectForKey(SerializationKey.prettyTime) as? String
        self.upvoteURL = aDecoder.decodeObjectForKey(SerializationKey.upvoteURL) as? String
    }

    public func encodeWithCoder(aCoder: NSCoder) {
        self.encode(self.title, key: SerializationKey.title, coder: aCoder)
        self.encode(self.username, key: SerializationKey.username, coder: aCoder)
        self.encode(self.url, key: SerializationKey.url, coder: aCoder)
        self.encode(self.points, key: SerializationKey.points, coder: aCoder)
        self.encode(self.commentsCount, key: SerializationKey.commentsCount, coder: aCoder)
        self.encode(self.prettyTime, key: SerializationKey.prettyTime, coder: aCoder)
        self.encode(self.postId, key: SerializationKey.postId, coder: aCoder)
        self.encode(self.upvoteURL, key: SerializationKey.upvoteURL, coder: aCoder)
    }

    private func encode(object: AnyObject!, key: String, coder: NSCoder) {
        if let value: AnyObject = object {
            coder.encodeObject(object, forKey: key)
        }
    }
}

//MARK: Equatable implementation
public func ==(larg: Post, rarg: Post) -> Bool {
    return larg.postId == rarg.postId
}

//MARK: Network
public extension Post {
    
    public typealias Response = (posts: [Post]!, error: Fetcher.ResponseError!, local: Bool) -> Void
    public typealias ResponsePost = (post: Post!, error: Fetcher.ResponseError!, local: Bool) -> Void
    
    public class func fetch(filter: PostFilter, page: Int, completion: Response) {
        Fetcher.Fetch(filter.toRaw() + "?p=\(page)",
            parsing: {(html) in
                if let realHtml = html {
                    var posts = self.parseCollectionHTML(realHtml)
                    return posts
                } else {
                    return nil
                }
            },
            completion: {(object, error, local) in
                if let realObject: AnyObject = object {
                    completion(posts: realObject as [Post], error: error, local: local)
                }
                else {
                    completion(posts: nil, error: error, local: local)
                }
        })
    }
    
    public class func fetch(filter: PostFilter, completion: Response) {
        fetch(filter, page: 1, completion: completion)
    }
    
    public class func fetch(user: String, page: Int, lastPostId:String?, completion: Response) {
        var additionalParameters = ""
        if let lastPostIdInt = lastPostId?.toInt() {
            additionalParameters = "&next=\(lastPostIdInt-1)"
        }
        Fetcher.Fetch("submitted?id=" + user + additionalParameters,
            parsing: {(html) in
                if let realHtml = html {
                    var posts = self.parseCollectionHTML(realHtml)
                    return posts
                } else {
                    return nil
                }
            },
            completion: {(object, error, local) in
                if let realObject: AnyObject = object {
                    completion(posts: realObject as [Post], error: error, local: local)
                }
                else {
                    completion(posts: nil, error: error, local: local)
                }
        })
    }
    
    public class func fetch(user: String, completion: Response) {
        fetch(user, page: 1, lastPostId:nil, completion: completion)
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

//MARK: HTML
internal extension Post {
    
    internal class func parseCollectionHTML(html: String) -> [Post] {
        var components = html.componentsSeparatedByString("<tr><td align=\"right\" valign=\"top\" class=\"title\">")
        var posts: [Post] = []
        if (components.count > 0) {
            var index = 0
            for component in components {
                if index != 0 {
                    posts.append(Post(html: component))
                }
                index++
            }
        }
        return posts
    }
    
    internal func parseHTML(html: String) {
        var scanner = NSScanner(string: html)
        
        if (html.rangeOfString("<td class=\"title\"> [dead] <a") == nil) {
            
            self.url = NSURL(string: scanner.scanTag("<a href=\"", endTag: "\""))
            self.title = scanner.scanTag(">", endTag: "</a>")
            
            var temp: NSString = scanner.scanTag("<span id=\"score_", endTag: "</span>")
            var range = temp.rangeOfString(">")
            if (range.location != NSNotFound) {
                self.points = temp.substringFromIndex(range.location + 1).toInt()
            }
            
            self.username = scanner.scanTag("<a href=\"user?id=", endTag: "\"")
            if self.username == nil {
                self.username = "HN"
            }
            self.prettyTime = scanner.scanTag("</a> ", endTag: "ago") + "ago"
            self.postId = scanner.scanTag("<a href=\"item?id=", endTag: "\">")
            
            temp = scanner.scanTag("\">", endTag: "</a>")
            if (temp == "discuss") {
                self.commentsCount = 0
            }
            else {
                self.commentsCount = temp.integerValue
            }
            if (self.username == nil && self.commentsCount == 0 && self.postId == nil) {
                self.type = PostFilter.Jobs
            }
            else if (self.url?.absoluteString?.localizedCaseInsensitiveCompare("http") == nil) {
                self.type = PostFilter.Ask
                if let realURL = self.url {
                    var url = realURL.absoluteString
                    self.url = NSURL(string: "https://news.ycombinator.com/" + url!)
                }
            }
            else {
                self.type = PostFilter.Default
            }
        }
    }
}
