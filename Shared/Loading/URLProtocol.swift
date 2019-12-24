//
//  KiwixURLProtocol.swift
//  Kiwix
//
//  Created by Chris Li on 8/14/15.
//  Copyright © 2015 Chris Li. All rights reserved.


class KiwixURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.scheme?.caseInsensitiveCompare("Kiwix") == .orderedSame ? true : false
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
        
        guard let content = ZimMultiReader.shared.getContent(bookID: id, contentPath: contentPath),
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": content.mime, "Content-Length": "\(content.length)"]) else {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: nil)
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
        client?.urlProtocol(self, didLoad: content.data)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        return
    }
}


