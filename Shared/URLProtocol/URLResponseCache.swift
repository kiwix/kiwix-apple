//
//  URLResponseCache.swift
//  Kiwix
//
//  Created by Chris Li on 7/18/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//


class URLResponseCache {
    static let shared = URLResponseCache()
    private(set) var isListening = false
    private var responses = [URL: URLResponse]()
    
    private init() {}
    
    func start() {
        clear()
        isListening = true
    }
    
    func stop() {
        isListening = false
    }
    
    func clear() {
        responses.removeAll()
    }
    
    func cache(response: URLResponse) {
        guard isListening, let url = response.url else {return}
        responses[url] = response
    }
    
    func firstImage() -> URL? {
        let response = responses.filter({ $1.mimeType?.contains("image") ?? false }).first?.1
        return response?.url
    }
}
