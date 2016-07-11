//
//  KiwixURLProtocol.swift
//  Kiwix
//
//  Created by Chris Li on 8/14/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//  http://www.raywenderlich.com/76735/using-nsurlprotocol-swift

class KiwixURLProtocol: NSURLProtocol {
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        return request.URL?.scheme.caseInsensitiveCompare("Kiwix") == .OrderedSame ? true : false
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(aRequest: NSURLRequest, toRequest bRequest: NSURLRequest) -> Bool {
        return super.requestIsCacheEquivalent(aRequest, toRequest:bRequest)
    }
    
    override func startLoading() {
        if let id = self.request.URL?.host, let contentURLString = self.request.URL?.path?.stringByRemovingPercentEncoding {
            if let dataDic = ZimMultiReader.sharedInstance.data(id, contentURLString: contentURLString),
                data = dataDic["data"] as? NSData,
                mimeType = dataDic["mime"] as? String,
                dataLength = dataDic["length"]?.integerValue {
                //print(String(data: data, encoding: NSUTF8StringEncoding))
                let response = NSURLResponse(URL: self.request.URL!, MIMEType: mimeType, expectedContentLength: dataLength, textEncodingName: nil)
                self.client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .Allowed)
                self.client?.URLProtocol(self, didLoadData: data)
                self.client?.URLProtocolDidFinishLoading(self)
            } else {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: nil)
                self.client?.URLProtocol(self, didFailWithError: error)
            }
        } else {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: nil)
            self.client?.URLProtocol(self, didFailWithError: error)
        }
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
        guard let contentURLString = ZimMultiReader.sharedInstance.pageURLString(articleTitle, bookid: id) else {
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
