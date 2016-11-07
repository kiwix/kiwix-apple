//
//  KiwixURL.swift
//  Kiwix
//
//  Created by Chris Li on 9/9/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

extension URL {
    init?(bookID: String, contentPath: String) {
        let baseURLString = "kiwix://" + bookID
        (self as NSURL).init(string: contentPath, relativeTo: URL(string: baseURLString))
    }
    
    var isKiwixURL: Bool {
        return scheme?.caseInsensitiveCompare("kiwix") == .orderedSame
    }
}
