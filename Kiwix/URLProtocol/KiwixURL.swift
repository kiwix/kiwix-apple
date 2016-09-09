//
//  KiwixURL.swift
//  Kiwix
//
//  Created by Chris Li on 9/9/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

extension NSURL {
    convenience init?(bookID: String, contentPath: String) {
        let baseURLString = "kiwix://" + bookID
        self.init(string: contentPath, relativeToURL: NSURL(string: baseURLString))
    }
    
    var isKiwixURL: Bool {
        return scheme?.caseInsensitiveCompare("kiwix") == .OrderedSame
    }
}
