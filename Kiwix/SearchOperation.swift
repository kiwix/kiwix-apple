//
//  SearchOperation.swift
//  Kiwix
//
//  Created by Chris Li on 4/9/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class SearchOperation: GroupOperation {
    var completionHandler: ([SearchResult]) -> Void

    init(searchTerm: String, completionHandler: ([SearchResult]) -> Void) {
        self.completionHandler = completionHandler
        super.init(operations: [NSOperation]())
    }
}
