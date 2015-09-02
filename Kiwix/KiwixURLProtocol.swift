//
//  KiwixURLProtocol.swift
//  Kiwix
//
//  Created by Chris Li on 8/14/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//  http://www.raywenderlich.com/76735/using-nsurlprotocol-swift

import UIKit

class KiwixURLProtocol: NSURLProtocol {
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        if request.URL?.scheme.caseInsensitiveCompare("Kiwix") == .OrderedSame {
            return true
        } else {
            return false
        }
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(aRequest: NSURLRequest,
        toRequest bRequest: NSURLRequest) -> Bool {
            return super.requestIsCacheEquivalent(aRequest, toRequest:bRequest)
    }
    
    override func startLoading() {
        if let idString = self.request.URL?.host, let contentURLString = self.request.URL?.path?.stringByRemovingPercentEncoding {
            if let dataDic = ZimMultiReader.sharedInstance.data(withZimFileID: idString, contentURLString: contentURLString),
                data = dataDic["data"] as? NSData,
                mimeType = dataDic["mime"] as? String,
                dataLength = dataDic["length"]?.integerValue {
                    let response = NSURLResponse(URL: self.request.URL!, MIMEType: (mimeType == "text/html; charset=utf-8" ? "text/html" : mimeType), expectedContentLength: dataLength, textEncodingName: nil)
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
    class func kiwixURLWithZimFileIDString(idString: String, contentURLString: String) -> NSURL {
        if let escapedContentURLString = contentURLString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet()) {
            let baseURLString = "kiwix://" + idString
            return NSURL(string: escapedContentURLString, relativeToURL: NSURL(string: baseURLString))!
        } else {
            print("Unable to escape characters in contentURLString, is going to replace contentURL by empty string")
            return NSURL(scheme: "Kiwix", host: idString, path: "")!
        }
    }
}
