//
//  URLContent.swift
//  Kiwix
//
//  Created by Chris Li on 11/6/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

/// Content of a URL retrieved from zim files.
struct URLContent {
    let data: Data
    let mime: String
    let length: Int
}
