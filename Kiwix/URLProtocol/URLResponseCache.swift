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
    fileprivate(set) var listening = false
    fileprivate var responses = [URL: URLResponse]()
    
    func start() {
        listening = true
        clear()
    }
    
    func stop() {
        listening = false
    }
    
    func clear() {
        responses.removeAll()
    }
    
    func cache(response: URLResponse) {
        guard listening else {return}
        guard let url = response.url else {return}
        responses[url] = response
    }
    
    func firstImage() -> URL? {
        let response = responses.filter({ $1.mimeType?.contains("image") ?? false }).first?.1
        return response?.url
    }
}
