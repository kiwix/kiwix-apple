//
//  CloudKitOperations.swift
//  Kiwix
//
//  Created by Chris Li on 11/27/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CloudKit
import ProcedureKit

class BookmarkSyncOperation: Procedure {
    let articleURL: URL
    
    init(articleURL: URL) {
        self.articleURL = articleURL
        super.init()
    }

}
