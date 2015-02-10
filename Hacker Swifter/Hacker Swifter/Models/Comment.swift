//
//  Comment.swift
//  HackerSwifter
//
//  Created by Tosin Afolabi on 17/07/2014.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

@objc(Comment) public class Comment: NSObject, NSCoding, Equatable {
    
    public var type: CommentFilter?
    public var text: String?
    public var username: String?
    public var depth: Int = 0
    public var commentId: String?
    public var parentId: String?
    public var prettyTime: String?
    public var links: [NSURL]?
    public var replyURLString: String?
    public var upvoteURLAddition: String?
    public var downvoteURLAddition: String?
    
    public enum CommentFilter: String {
        case Default = "default"
        case Ask = "ask"
        case Jobs = "jobs"
    }
    
    internal enum serialization: String {
        case text = "text"
        case username = "username"
        case depth = "depth"
        case commentId = "commentId"
        case parentId = "parentId"
        case prettyTime = "prettyTime"
        case links = "links"
        case replyURLString = "replyURLString"
        case upvoteURLAddition = "upvoteURLAddition"
        case downvoteURLAddition = "downvoteURLAddition"
        
        static let values = [text, username, depth, commentId, parentId, prettyTime, links,
            replyURLString, upvoteURLAddition, downvoteURLAddition]
    }
    
    public override init(){
        super.init()
    }
    
    public init(html: String, type: Post.PostFilter) {
        super.init()
        self.parseHTML(html, withType: type)
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init()
        
        for key in serialization.values {
            setValue(aDecoder.decodeObjectForKey(key.rawValue), forKey: key.rawValue)
        }
    }
    
    public func encodeWithCoder(aCoder: NSCoder)  {
        for key in serialization.values {
            if let value: AnyObject = self.valueForKey(key.rawValue) {
                aCoder.encodeObject(value, forKey: key.rawValue)
            }
        }
    }
}

//MARK: Equatable implementation
public func ==(larg: Comment, rarg: Comment) -> Bool {
    return larg.commentId == rarg.commentId
}

//MARK: Network
public extension Comment {
    
    typealias Response = (comments: [Comment]!, error: Fetcher.ResponseError!, local: Bool) -> Void
    
    public class func fetch(forPost post: Post, completion: Response) {
        let ressource = "item?id=" + post.postId!
        Fetcher.Fetch(ressource,
            parsing: {(html) in
                var type = post.type
                if type == nil {
                    type = Post.PostFilter.Default
                }
                
                if let realHtml = html {
                    var comments = self.parseCollectionHTML(realHtml, withType: type!)
                    return comments
                }
                else {
                    return nil
                }
            },
            completion: {(object, error, local) in
                if let realObject: AnyObject = object {
                    completion(comments: realObject as [Comment], error: error, local: local)
                }
                else {
                    completion(comments: nil, error: error, local: local)
                }
        })
    }
}



//MARK: HTML
internal extension Comment {
    
    internal class func parseCollectionHTML(html: String, withType type: Post.PostFilter) -> [Comment] {
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
                    comments.append(Comment(html: component, type: type))
                }
                index++
            }
        }
        return comments
    }
    
    internal func parseHTML(html: String, withType type: Post.PostFilter) {
        var scanner = NSScanner(string: html)
        
        var level = scanner.scanTag("height=\"1\" width=\"", endTag: ">")
        if let unwrappedLevel = level.substringToIndex(advance(level.startIndex, countElements(level) - 1)).toInt() {
            self.depth = unwrappedLevel / 40
        } else {
            self.depth = 0
        }
        
        var username = scanner.scanTag("<a href=\"user?id=", endTag: "\">")
        self.username = username.utf16Count > 0 ? username : "[deleted]"
        self.commentId = scanner.scanTag("<a href=\"item?id=", endTag: "\">")
        self.prettyTime = scanner.scanTag(">", endTag: "</a>")
        
        if (html.rangeOfString("[deleted]")?.startIndex != nil) {
            self.text = "[deleted]"
        } else {
            let textTemp = scanner.scanTag("<font color=", endTag: "</font>") as String
            if (countElements(textTemp)>0) {
                self.text = String.stringByRemovingHTMLEntities(textTemp.substringFromIndex(advance(textTemp.startIndex, 10)))
            }
            else {
                self.text = ""
            }
        }
        
        //LOL, it whould always work, as I strip a Hex color, which is always the same length
        
        self.replyURLString = scanner.scanTag("<font size=1><u><a href=\"", endTag: "\">reply")
        self.type = CommentFilter.Default
    }
}

