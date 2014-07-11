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
        var result: NSString? = NSString(string: "")
        if (string.utf16count > 0) {
            self.scanUpToString(startTag, intoString: nil)
            self.scanLocation += startTag.utf16count
            self.scanUpToString(endTag, intoString: &result)
        }
        return result!
    }
}