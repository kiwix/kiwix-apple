//
//  URLResponseCache.swift
//  Kiwix
//
//  Created by Chris Li on 7/18/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class URLResponseCache {
    static let shared = URLResponseCache()
    private(set) var listening = false
    private var responses = [NSURL: NSURLResponse]()
    
    func start() {
        listening = true
    }
    
    func stop() {
        listening = false
        responses.removeAll()
    }
    
    func cache(response response: NSURLResponse) {
        guard let url = response.URL else {return}
        responses[url] = response
    }
    
    func firstImage() -> NSURL? {
        let response = responses.filter({ $1.MIMEType?.containsString("image") ?? false }).first?.1
        return response?.URL
    }
}
