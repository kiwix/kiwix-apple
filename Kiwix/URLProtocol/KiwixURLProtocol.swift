//
//  KiwixURLProtocol.swift
//  Kiwix
//
//  Created by Chris Li on 8/14/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//  http://www.raywenderlich.com/76735/using-nsurlprotocol-swift

class KiwixURLProtocol: NSURLProtocol {
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        return request.URL?.scheme!.caseInsensitiveCompare("Kiwix") == .OrderedSame ? true : false
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(aRequest: NSURLRequest, toRequest bRequest: NSURLRequest) -> Bool {
        return super.requestIsCacheEquivalent(aRequest, toRequest:bRequest)
    }
    
    override func startLoading() {
        guard let url = request.URL,
            let id = url.host,
            let contentURLString = url.path?.stringByRemovingPercentEncoding else {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: nil)
                client?.URLProtocol(self, didFailWithError: error)
                return
        }
        guard let dataDic = ZimMultiReader.shared.data(id, contentURLString: contentURLString),
            let data = dataDic["data"] as? NSData,
            let mimeType = dataDic["mime"] as? String,
            let dataLength = dataDic["length"]?.integerValue else {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: nil)
                client?.URLProtocol(self, didFailWithError: error)
                return
        }
        
        let response = NSURLResponse(URL: url, MIMEType: mimeType, expectedContentLength: dataLength, textEncodingName: nil)
        URLResponseCache.shared.cache(response: response)
        
        client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .Allowed)
        client?.URLProtocol(self, didLoadData: data)
        client?.URLProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        return
        
    }
}

extension NSURL {
    
    
    class func kiwixURLWithZimFileid(id: String, contentURLString: String) -> NSURL? {
        guard let escapedContentURLString = contentURLString.stringByAddingPercentEncodingWithAllowedCharacters(.URLPathAllowedCharacterSet()) else {return nil}
        let baseURLString = "kiwix://" + id
        return NSURL(string: escapedContentURLString, relativeToURL: NSURL(string: baseURLString))
    }
    
    class func kiwixURLWithZimFileid(id: String, articleTitle: String) -> NSURL? {
        guard let contentURLString = ZimMultiReader.shared.pageURLString(articleTitle, bookid: id) else {
            print("ZimMultiReader cannot get pageURLString from \(articleTitle) in book \(id)")
            return nil
        }
        return NSURL.kiwixURLWithZimFileid(id, contentURLString: contentURLString)
    }
    
    convenience init?(id: ZimID, contentURLString: String) {
        guard let escapedContentURLString = contentURLString.stringByAddingPercentEncodingWithAllowedCharacters(.URLPathAllowedCharacterSet()) else {return nil}
        let baseURLString = "kiwix://" + id
        self.init(string: escapedContentURLString, relativeToURL: NSURL(string: baseURLString))
    }
}
