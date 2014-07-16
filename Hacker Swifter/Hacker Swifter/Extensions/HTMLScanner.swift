//
//  HTMLScanner.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

extension NSScanner {
    func scanTag(startTag: String, endTag: String) -> String {
        var temp: NSString? = ""
        var result: NSString? = ""
        self.scanUpToString(startTag, intoString: &temp)
        self.scanString(startTag, intoString: &temp)
        self.scanUpToString(endTag, intoString: &result)
        return result as String
    }
}