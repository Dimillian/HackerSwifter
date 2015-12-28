//
//  Post.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

@objc(Item) public class Item: NSObject, NSCoding {
    
    public var id: Int = 0
    public var title: String?
    public var username: String?
    public var url: NSURL?
    public var text: String?
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
    public var commentsCount: Int = 0
    public var type: String?
    public var kids: [Int]?
    public var score: Int = 0
    public var time: Double = 0
    public var dead: Bool = false
    
    internal enum serialization: String {
        case id = "id"
        case title = "title"
        case username = "username"
        case url = "url"
        case commentsCount = "commentsCount"
        case type = "type"
        case score = "score"
        case time = "time"
        case text = "text"
        
        static let values = [id, title, username, url, commentsCount, type, score, time, text]
    }
    
    internal enum JSONField: String {
        case id = "id"
        case by = "by"
        case descendants = "descendants"
        case kids = "kids"
        case score = "score"
        case time = "time"
        case title = "title"
        case type = "type"
        case url = "url"
        case dead = "dead"
        case text = "text"
    }
    
    public override init(){
        super.init()
    }
    
    public init(id: Int) {
        super.init()
        self.id = id
    }
    
    public init(json: NSDictionary) {
        super.init()
        self.parseJSON(json)
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
        if let _: AnyObject = object {
            coder.encodeObject(object, forKey: key)
        }
    }
}

//MARK: Equatable implementation
public func ==(larg: Item, rarg: Item) -> Bool {
    return larg.id == rarg.id
}

//MARK: Network
public extension Item {
    
    public typealias Response = (item: Item!, error: Fetcher.ResponseError!, local: Bool) -> Void
    public typealias ResponsePosts = (items: [Int]!, error: Fetcher.ResponseError!, local: Bool) -> Void
    

    public class func fetchPost(filter: Fetcher.APIEndpoint, completion: ResponsePosts) {
        Fetcher.FetchJSON(filter, ressource: nil, parsing: { (json) -> AnyObject! in
            if let _ = json as? [Int] {
                return json
            }
            return nil
            }) { (object, error, local) -> Void in
                completion(items: object as? [Int] , error: error, local: local)
        }
    }
    
    public class func fetchPost(post: Int, completion: Response) {
        Fetcher.FetchJSON(.Post, ressource: String(post), parsing: { (json) -> AnyObject! in
            if let dic = json as? NSDictionary {
                return Item(json: dic)
            }
            return nil
            }) { (object, error, local) -> Void in
                completion(item: object as? Item , error: error, local: local)
        }
    }


    
    public class func fetchPost(user: String, completion: ResponsePosts) {
        Fetcher.FetchJSON(.User, ressource: user, parsing: { (json) -> AnyObject! in
            if let _ = json as? NSDictionary {
                return json
            }
            return nil
            }) { (object, error, local) -> Void in
                if let json = object as? NSDictionary {
                    completion(items: json["submitted"] as! [Int], error: error, local: local)
                }
                else {
                    completion(items: nil, error: error, local: local)
                }
        }}
}

//MARK: JSON

internal extension Item {
    internal func parseJSON(json: NSDictionary) {
        self.id = json[JSONField.id.rawValue] as! Int
        if let kids = json[JSONField.kids.rawValue] as? [Int] {
            self.kids = kids
        }
        self.title = json[JSONField.title.rawValue] as? String
        if let score = json[JSONField.score.rawValue] as? Int {
            self.score = score;
        }
        self.username = json[JSONField.by.rawValue] as? String
        self.time = json[JSONField.time.rawValue] as! Double
        if let url = json[JSONField.url.rawValue] as? String {
            self.url = NSURL(string: url)
        }
        if let commentsCount = json[JSONField.descendants.rawValue] as? Int {
            self.commentsCount = commentsCount
        }
        if let _ = json[JSONField.dead.rawValue] as? Bool {
            self.dead = true
        }
        if let text = json[JSONField.text.rawValue] as? String {
            self.text = text
        }
    }
}
