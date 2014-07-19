//
//  User.swift
//  HackerSwifter
//
//  Created by Tosin Afolabi on 18/07/2014.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

class User: NSObject, NSCoding {

    var username: String?
    var karma: Int?
    var age: Int?
    var info: String?

    struct SerializationKey {
        static let username = "username"
        static let karma = "karma"
        static let age = "age"
        static let info = "info"
        static let allKeys = [username, karma, age, info]
    }

    init(){
        super.init()
    }

    // We might want to do a Mantle like thing with magic keys matching

    init(coder aDecoder: NSCoder!) {

        /*
        super.init()
        for key in SerializationKey.allKeys {
            self.setValue(aDecoder.decodeObjectForKey(key), forKey: key)
        }
        */

        /*
        self.username = aDecoder.decodeObjectForKey(SerializationKey.username) as? String
        self.karma = aDecoder.decodeObjectForKey(SerializationKey.karma) as? Int
        self.age = aDecoder.decodeObjectForKey(SerializationKey.age) as? Int
        self.info = aDecoder.decodeObjectForKey(SerializationKey.info) as? String
        */
    }

    func encodeWithCoder(aCoder: NSCoder!) {

        /*

        for key in SerializationKey.allKeys {
            aCoder.encodeObject(self.valueForKey(key), forKey: key)
        }
        
        */

        // If they were all String?, its good, but it fails at Int?

        aCoder.encodeObject(self.username, forKey: SerializationKey.username)
        aCoder.encodeObject(self.karma, forKey: SerializationKey.karma)
        aCoder.encodeObject(self.age, forKey: SerializationKey.age)
        aCoder.encodeObject(self.info, forKey: SerializationKey.info)



    }
}

//Network
extension User {

    typealias Response = (user: User!, error: Fetcher.ResponseError!, local: Bool) -> Void

    class func fetch(forUser username: String, completion: Response) {
        let ressource = "user?id=\(username)"
        Fetcher.Fetch(ressource,
            parsing: {(html) in
                if let realHtml = html {
                    var user = User()
                    user.parseHTML(realHtml)
                    return user
                }
                else {
                    return nil
                }
            },
            completion: {(object, error, local) in
                completion(user: object as User, error: error, local: local)
            })
    }
}

//HTML
extension User {

    func parseHTML(html: String) {
        var scanner = NSScanner(string: html)
        self.username = scanner.scanTag("user:</td><td>", endTag: "</td>")
    }
}


