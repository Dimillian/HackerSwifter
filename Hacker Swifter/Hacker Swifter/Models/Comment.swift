//
//  Comment.swift
//  HackerSwifter
//
//  Created by Tosin Afolabi on 17/07/2014.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

@objc(Comment) class Comment: NSObject, NSCoding {

    var type: CommentFilter?
    var text: String?
    var username: String?
    var depth: Int?
    var commentId: String?
    var parentId: String?
    var prettyTime: String?
    var links: [NSURL]?
    var replyURLString: String?
    var upvoteURLAddition: String?
    var downvoteURLAddition: String?

    enum CommentFilter: String {
        case Default = "default"
        case Ask = "ask"
        case Jobs = "jobs"
    }

    struct SerializationKey {
        static let type = "title"
        static let text = "text"
        static let username = "username"
        static let depth = "depth"
        static let commentId = "commentId"
        static let parentId = "parentId"
        static let prettyTime = "time"
        static let links = "links"
        static let replyURLString = "replyURLString"
        static let upvoteURLAddition = "upvoteURLAddition"
        static let downvoteURLAddition = "downvoteURLAddition"
    }

    init() {
        super.init()
    }

    init(coder aDecoder: NSCoder!) {
        self.text = aDecoder.decodeObjectForKey(SerializationKey.text) as? String
        self.username = aDecoder.decodeObjectForKey(SerializationKey.username) as? String
        self.depth = aDecoder.decodeObjectForKey(SerializationKey.depth) as? Int
        self.commentId = aDecoder.decodeObjectForKey(SerializationKey.commentId) as? String
        self.parentId = aDecoder.decodeObjectForKey(SerializationKey.parentId) as? String
        self.prettyTime = aDecoder.decodeObjectForKey(SerializationKey.prettyTime) as? String
        self.links = aDecoder.decodeObjectForKey(SerializationKey.links) as? [NSURL]
        self.replyURLString = aDecoder.decodeObjectForKey(SerializationKey.replyURLString) as? String
        self.upvoteURLAddition = aDecoder.decodeObjectForKey(SerializationKey.upvoteURLAddition) as? String
        self.downvoteURLAddition = aDecoder.decodeObjectForKey(SerializationKey.downvoteURLAddition) as? String
    }

    func encodeWithCoder(aCoder: NSCoder!) {
        aCoder.encodeObject(self.text, forKey: SerializationKey.text)
        aCoder.encodeObject(self.username, forKey: SerializationKey.username)
        aCoder.encodeObject(self.depth, forKey: SerializationKey.depth)
        aCoder.encodeObject(self.commentId, forKey: SerializationKey.commentId)
        aCoder.encodeObject(self.parentId, forKey: SerializationKey.parentId)
        aCoder.encodeObject(self.prettyTime, forKey: SerializationKey.prettyTime)
        aCoder.encodeObject(self.links, forKey: SerializationKey.links)
        aCoder.encodeObject(self.replyURLString, forKey: SerializationKey.replyURLString)
        aCoder.encodeObject(self.upvoteURLAddition, forKey: SerializationKey.upvoteURLAddition)
        aCoder.encodeObject(self.downvoteURLAddition, forKey: SerializationKey.downvoteURLAddition)
    }
}

// Network
extension Comment {

    typealias Response = (comments: [Comment]!, error: Fetcher.ResponseError!, local: Bool) -> Void

    class func fetch(forPost post: Post, completion: Response) {
        let resource = "item?id=\(post.postId)"
        Fetcher.Fetch(resource,
            parsing: {(html) in
                if let realHtml = html {
                    var comments = self.parseCollectionHTML(realHtml, withType: post.type!)
                    return comments
                }
                else {
                    return nil
                }
            },
            completion: {(object, error, local) in
                completion(comments: object as [Comment], error: error, local: local)
            })
    }
}



//HTML
extension Comment {

    class func parseCollectionHTML(html: String, withType type: Post.PostFilter) -> [Comment] {
        var components = html.componentsSeparatedByString("<td><img src=\"s.gif\"")
        var comments: [Comment] = []
        if (components.count > 0) {
            if (type == Post.PostFilter.Ask) {
                var scanner = NSScanner(string: components[0])
                var comment = Comment()
                comment.type = CommentFilter.Ask
                comment.commentId = scanner.scanTag("<span id=\"score_", endTag: ">")
                comment.username = scanner.scanTag("by <a href=\"user?id=", endTag: "\">")
                comment.prettyTime = scanner.scanTag("</a> ", endTag: "ago") + "ago"
                comment.text = String.stringByRemovingHTMLEntities(scanner.scanTag("</tr><tr><td></td><td>", endTag: "</td>"))
                comment.depth = 0
                comments.append(comment)
            }
                
            else if (type == Post.PostFilter.Jobs) {
                var scanner = NSScanner(string: components[0])
                var comment = Comment()
                comment.depth = 0
                comment.text = String.stringByRemovingHTMLEntities(scanner.scanTag("</tr><tr><td></td><td>", endTag: "</td>"))
                comment.type = CommentFilter.Jobs
                comments.append(comment)
            }
            
            var index = 0
            
            for component in components {
                if index != 0 && index != components.count - 1 {
                    var comment = Comment()
                    comment.parseHTML(component, withType: type)
                    comments.append(comment)
                }
                index++
            }
        }
        return comments
    }

    func parseHTML(html: String, withType type: Post.PostFilter) {
        var scanner = NSScanner(string: html)
        
        var level: NSString = scanner.scanTag("height=\"1\" width=\"", endTag: ">")
        self.depth = level.integerValue / 40
        
        var username = scanner.scanTag("<a href=\"user?id=", endTag: "\">")
        self.username = username.utf16count > 0 ? username : "[deleted]"
        
        self.prettyTime = scanner.scanTag("</a> ", endTag: " |")
        self.text = String.stringByRemovingHTMLEntities(scanner.scanTag("<font color=", endTag: "</font>").substringFromIndex(10))
        //LOL, it whould always work, as I strip a Hex color, which is always the same length
        
        self.commentId = scanner.scanTag("reply?id=", endTag: "&")
        self.replyURLString = scanner.scanTag("<font size=1><u><a href=\"", endTag: "\">reply")
        self.type = CommentFilter.Default
        
    }
}

