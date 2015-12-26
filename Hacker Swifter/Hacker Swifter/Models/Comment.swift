//
//  Comment.swift
//  HackerSwifter
//
//  Created by Tosin Afolabi on 17/07/2014.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

@objc public class Comment: NSObject, NSCoding {
    
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
    
    
    public required init?(coder aDecoder: NSCoder) {
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

    }
}
