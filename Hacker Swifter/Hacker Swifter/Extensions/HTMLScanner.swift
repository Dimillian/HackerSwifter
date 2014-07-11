//
//  HTMLScanner.swift
//  Hacker Swifter
//
//  Created by Thomas Ricouard on 11/07/14.
//  Copyright (c) 2014 Thomas Ricouard. All rights reserved.
//

import Foundation

extension NSScanner {
    class func scanString(string: String, startTag: String, endTag: String) -> String {
        var result: NSString? = NSString(string: "")
        if (string.utf16count > 0) {
            var scanner = NSScanner(string: string)
            scanner.scanUpToString(startTag, intoString: nil)
            scanner.scanLocation += startTag.utf16count
            scanner.scanUpToString(endTag, intoString: &result)
        }
        return result!
    }
}