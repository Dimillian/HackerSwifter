//
//  HTMLScanner.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

extension Scanner {
    func scanTag(_ startTag: String, endTag: String) -> String {
        var temp: NSString? = ""
        var result: NSString? = ""
        self.scanUpTo(startTag, into: &temp)
        self.scanString(startTag, into: &temp)
        self.scanUpTo(endTag, into: &result)
        return result as! String
    }
}
