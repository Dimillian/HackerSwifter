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

    enum SerializationKey: String {
        case type = "title"
        case text = "text"
        case username = "username"
        case depth = "depth"
        case commentId = "commentId"
        case parentId = "parentId"
        case prettyTime = "time"
        case links = "links"
        case replyURLString = "replyURLString"
        case upvoteURLAddition = "upvoteURLAddition"
        case downvoteURLAddition = "downvoteURLAddition"
        
        static let allValues =
        [text, username, depth, commentId, parentId, prettyTime, links, replyURLString, upvoteURLAddition, downvoteURLAddition]
    }

    init() {
        super.init()
    }

    init(coder aDecoder: NSCoder!) {
        super.init()
        for key in SerializationKey.allValues {
            setValue(aDecoder.decodeObjectForKey(key.toRaw()), forKey: key.toRaw())
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder!) {   
        for key in SerializationKey.allValues {
            if let value: AnyObject = self.valueForKey(key.toRaw()) {
                aCoder.encodeObject(value, forKey: key.toRaw())
            }
        }
    }
}

// Network
extension Comment {

    typealias Response = (comments: [Comment]!, error: Fetcher.ResponseError!, local: Bool) -> Void

    class func fetch(forPost post: Post, completion: Response) {
        let ressource = "item?id=\(post.postId)"
        Fetcher.Fetch(ressource,
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

