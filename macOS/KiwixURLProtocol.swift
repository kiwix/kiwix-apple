//
//  KiwixURLProtocol.swift
//  Kiwix
//
//  Created by Chris Li on 8/14/15.
//  Copyright © 2015 Chris Li. All rights reserved.

import Foundation
import AppKit

class KiwixURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.scheme!.caseInsensitiveCompare("Kiwix") == .orderedSame ? true : false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(_ aRequest: URLRequest, to bRequest: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(aRequest, to:bRequest)
    }
    
    override func startLoading() {
        guard let url = request.url,
            let contentPath = url.path.removingPercentEncoding,
            let id = url.host else {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: nil)
                client?.urlProtocol(self, didFailWithError: error)
                return
        }
        
        guard let content = ZimManager.shared.getContent(bookID: id, contentPath: contentPath) else {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: nil)
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        let response = URLResponse(url: url, mimeType: content.mime, expectedContentLength: content.length, textEncodingName: nil)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
        client?.urlProtocol(self, didLoad: content.data)
        client?.urlProtocolDidFinishLoading(self)
        
//        guard let reader = (NSApplication.shared().delegate as! AppDelegate).reader else {return}
//        guard let dataDic = reader.data(withContentURLString: contentPath),
//            let data = dataDic["data"] as? Data,
//            let mimeType = dataDic["mime"] as? String,
//            let dataLength: Int = (dataDic["length"] as? NSNumber)?.intValue else {
//                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: nil)
//                client?.urlProtocol(self, didFailWithError: error)
//                return
//        }
//
//        let response = URLResponse(url: url, mimeType: mimeType, expectedContentLength: dataLength, textEncodingName: nil)
//
//        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
//        client?.urlProtocol(self, didLoad: data)
//        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        return
    }
}

extension URL {
    init?(bookID: String, contentPath: String) {
        let baseURLString = "kiwix://" + bookID
        guard let encoded = contentPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {return nil}
        self.init(string: encoded, relativeTo: URL(string: baseURLString))
    }
    
    var isKiwixURL: Bool {
        return scheme?.caseInsensitiveCompare("kiwix") == .orderedSame
    }
}
