//
//  User.swift
//  HackerSwifter
//
//  Created by Thomas Ricouard on 27/12/15.
//  Copyright © 2015 Thomas Ricouard. All rights reserved.
//

import Foundation

@objc(User) public class User: NSObject, NSCoding {
    
    public var id: Int = 0
    public var created: Double = 0
    public var karma: Int = 0
    public var about: String?
    public var submitted: [Int]?
    
    internal enum serialization: String {
        case id = "id"
        case created = "created"
        case karma = "karma"
        case about = "about"
        case submitted = "submitted"
        
        static let values = [id, created, karma, about, submitted]
    }
    
    
    public override init(){
        super.init()
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

//MARK: JSON

internal extension User {
    internal func parseJSON(json: NSDictionary) {
    }
}