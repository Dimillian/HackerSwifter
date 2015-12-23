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
            if let realUrl = self.url {
                if let host = realUrl.host {
                    if (host.hasPrefix("www")) {
                        return host.substringFromIndex(host.startIndex.advancedBy(4))
                    }
                    return host
                }
            }
            return ""
        }
    }
    public var points: Int = 0
    public var commentsCount: Int = 0
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
    
    internal enum serialization: String {
        case title = "title"
        case username = "username"
        case url = "url"
        case points = "points"
        case commentsCount = "commentsCount"
        case postId = "postId"
        case prettyTime = "prettyTime"
        case upvoteURL = "upvoteURL"
        
        static let values = [title, username, url, points, commentsCount, postId, prettyTime, upvoteURL]
    }
    
    public override init(){
        super.init()
    }
    
    public init(html: String) {
        super.init()
        self.parseHTML(html)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        
        for key in serialization.values {
            setValue(aDecoder.decodeObjectForKey(key.rawValue), forKey: key.rawValue)
        }
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        for key in serialization.values {
            if let value: AnyObject = self.valueForKey(key.rawValue) {
                aCoder.encodeObject(value, forKey: key.rawValue)
            }
        }
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
        Fetcher.Fetch(filter.rawValue + "?p=\(page)",
            parsing: {(html) in
                if let realHtml = html {
                    let posts = self.parseCollectionHTML(realHtml)
                    return posts
                } else {
                    return nil
                }
            },
            completion: {(object, error, local) in
                if let realObject: AnyObject = object {
                    completion(posts: realObject as! [Post], error: error, local: local)
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
        if let lastPostIdInt = Int((lastPostId)!) {
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
                    completion(posts: realObject as! [Post], error: error, local: local)
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
        let path = "items/" + post
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
        let components = html.componentsSeparatedByString("<td align=\"right\" valign=\"top\" class=\"title\">")
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
            
            var temp: NSString = scanner.scanTag("<span class=\"score\" id=\"score_", endTag: "</span>")
            var range = temp.rangeOfString(">")
            if (range.location != NSNotFound) {
                var tmpPoint: Int? = Int(temp.substringFromIndex(range.location + 1)
                    .stringByReplacingOccurrencesOfString(" points", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil))
                if let points = tmpPoint {
                    self.points = points
                }
                else {
                    self.points = 0
                }
            }
            else {
                self.points = 0
            }
            self.username = scanner.scanTag("<a href=\"user?id=", endTag: "\"")
            if self.username == nil {
                self.username = "HN"
            }
            self.postId = scanner.scanTag("<a href=\"item?id=", endTag: "\">")
            self.prettyTime = scanner.scanTag(">", endTag: "</a>")
            
            temp = scanner.scanTag("\">", endTag: "</a>")
            if (temp == "discuss") {
                self.commentsCount = 0
            }
            else {
                self.commentsCount = temp.integerValue
            }
            if (self.username == nil && self.commentsCount == 0 && self.postId == nil) {
                self.type = PostFilter.Jobs
                self.username = "Jobs"
            }
            else if (self.url?.absoluteString.localizedCaseInsensitiveCompare("http") == nil) {
                self.type = PostFilter.Ask
                if let realURL = self.url {
                    var url = realURL.absoluteString
                    self.url = NSURL(string: "https://news.ycombinator.com/" + url)
                }
            }
            else {
                self.type = PostFilter.Default
            }
        }
    }
}
