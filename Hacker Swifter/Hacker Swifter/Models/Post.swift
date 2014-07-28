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

    public init(){
        super.init()
    }
    
    public init(html: String) {
        super.init()
        self.parseHTML(html)
    }
    
    // We might want to do a Mantle like thing with magic keys matching
    
    public init(coder aDecoder: NSCoder!) {
        self.title = aDecoder.decodeObjectForKey(SerializationKey.title) as? String
        self.username = aDecoder.decodeObjectForKey(SerializationKey.username) as? String
        self.url = aDecoder.decodeObjectForKey(SerializationKey.url) as? NSURL
        self.points = aDecoder.decodeObjectForKey(SerializationKey.points) as? Int
        self.commentsCount = aDecoder.decodeObjectForKey(SerializationKey.commentsCount) as? Int
        self.postId = aDecoder.decodeObjectForKey(SerializationKey.postId) as? String
        self.prettyTime = aDecoder.decodeObjectForKey(SerializationKey.prettyTime) as? String
        self.upvoteURL = aDecoder.decodeObjectForKey(SerializationKey.upvoteURL) as? String
    }
    
    
    public func encodeWithCoder(aCoder: NSCoder!) {
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
          }
          else {
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
  
    public class func fetch(user: String, page: Int, completion: Response) {
      Fetcher.Fetch("submitted?id=" + user + "&p=\(page)", parsing: {(html) in
        if let realHtml = html {
          var posts = self.parseCollectionHTML(realHtml)
          return posts
        }
        else {
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
      fetch(user, page: 1, completion: completion)
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
