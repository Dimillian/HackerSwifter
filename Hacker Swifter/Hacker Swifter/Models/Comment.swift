//
//  Comment.swift
//  HackerSwifter
//
//  Created by Tosin Afolabi on 17/07/2014.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

@objc open class Comment: NSObject, NSCoding {
    
    open var type: CommentFilter?
    open var text: String?
    open var username: String?
    open var depth: Int = 0
    open var commentId: String?
    open var parentId: String?
    open var prettyTime: String?
    open var links: [URL]?
    open var replyURLString: String?
    open var upvoteURLAddition: String?
    open var downvoteURLAddition: String?
    
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
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        
        for key in serialization.values {
            setValue(aDecoder.decodeObject(forKey: key.rawValue), forKey: key.rawValue)
        }
    }
    
    open func encode(with aCoder: NSCoder)  {
        for key in serialization.values {
            if let value: AnyObject = self.value(forKey: key.rawValue) as AnyObject? {
                aCoder.encode(value, forKey: key.rawValue)
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
    
    typealias Response = (_ comments: [Comment]?, _ error: Fetcher.ResponseError?, _ local: Bool) -> Void
    
    public class func fetch(forPost post: Post, completion: @escaping Response) {
        let ressource = "item?id=" + post.postId!
        Fetcher.Fetch(ressource,
            parsing: {(html) in
                var type = post.type
                if type == nil {
                    type = Post.PostFilter.Default
                }
                
                if let realHtml = html {
                    let comments = self.parseCollectionHTML(realHtml, withType: type!)
                    return comments as AnyObject!
                }
                else {
                    return nil
                }
            },
            completion: {(object, error, local) in
                if let realObject: AnyObject = object {
                    completion(realObject as? [Comment], error, local)
                }
                else {
                    completion(nil, error, local)
                }
        })
    }
}



//MARK: HTML
internal extension Comment {
    
    internal class func parseCollectionHTML(_ html: String, withType type: Post.PostFilter) -> [Comment] {
        var components = html.components(separatedBy: "<tr><td class='ind'><img src=\"s.gif\"")
        var comments: [Comment] = []
        if (components.count > 0) {
            if (type == Post.PostFilter.Ask) {
                let scanner = Scanner(string: components[0])
                let comment = Comment()
                comment.type = CommentFilter.Ask
                comment.commentId = scanner.scanTag("<span id=\"score_", endTag: ">")
                comment.username = scanner.scanTag("by <a href=\"user?id=", endTag: "\">")
                comment.prettyTime = scanner.scanTag("</a> ", endTag: "ago") + "ago"
                comment.text = String.stringByRemovingHTMLEntities(scanner.scanTag("</tr><tr><td></td><td>", endTag: "</td>"))
                comment.depth = 0
                comments.append(comment)
            }
                
            else if (type == Post.PostFilter.Jobs) {
                let scanner = Scanner(string: components[0])
                let comment = Comment()
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
                index += 1
            }
        }
        return comments
    }
    
    internal func parseHTML(_ html: String, withType type: Post.PostFilter) {
        let scanner = Scanner(string: html)
        
        let level = scanner.scanTag("height=\"1\" width=\"", endTag: ">")
        if let unwrappedLevel = Int(level.substring(to: level.characters.index(level.startIndex, offsetBy: level.characters.count - 1))) {
            self.depth = unwrappedLevel / 40
        } else {
            self.depth = 0
        }
        
        let username = scanner.scanTag("<a href=\"user?id=", endTag: "\">")
        self.username = username.utf16.count > 0 ? username : "[deleted]"
        self.commentId = scanner.scanTag("<a href=\"item?id=", endTag: "\">")
        self.prettyTime = scanner.scanTag(">", endTag: "</a>")
        
        if (html.range(of: "[deleted]")?.lowerBound != nil) {
            self.text = "[deleted]"
        } else {
            let textTemp = scanner.scanTag("<font color=", endTag: "</font>") as String
            if (textTemp.characters.count>0) {
                self.text = String.stringByRemovingHTMLEntities(textTemp.substring(from: textTemp.characters.index(textTemp.startIndex, offsetBy: 10)))
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

