//
//  ArticleOperation.swift
//  Kiwix
//
//  Created by Chris Li on 9/7/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import Operations

class ArticleLoadOperation: Operation {
    let url: NSURL
    
    init?(url: NSURL) {
        self.url = url
        super.init()
    }
    
    override func execute() {
        
    }
    
}
