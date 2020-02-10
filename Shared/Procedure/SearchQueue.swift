//
//  SearchQueue.swift
//  iOS
//
//  Created by Chris Li on 4/18/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import SwiftyUserDefaults

class SearchQueue: OperationQueue {
    override init() {
        super.init()
        maxConcurrentOperationCount = 1
    }
}
