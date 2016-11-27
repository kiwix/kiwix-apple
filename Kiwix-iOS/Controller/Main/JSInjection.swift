//
//  JS.swift
//  Kiwix
//
//  Created by Chris Li on 9/9/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit
import JavaScriptCore

class JS {
    
    class func inject(webView: UIWebView) {
        guard let url = Bundle.main.url(forResource: "injection", withExtension: "js"),
            let jString = try? String(contentsOf: url) else {return}
        webView.stringByEvaluatingJavaScript(from: jString)
    }
    
    class func preventDefaultLongTap(webView: UIWebView) {
        let jString = "document.body.style.webkitTouchCallout='none';"
        webView.context.evaluateScript(jString)
    }
    
    class func adjustFontSizeIfNeeded(_ webView: UIWebView) {
        guard Preference.webViewZoomScale != 100.0 else {return}
        let jString = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", Preference.webViewZoomScale)
        webView.stringByEvaluatingJavaScript(from: jString)
    }
    
    class func getTitle(from webView: UIWebView) -> String? {
        return webView.stringByEvaluatingJavaScript(from: "document.title")
    }
    
    class func startTOCCallBack(_ webView: UIWebView) {
        webView.stringByEvaluatingJavaScript(from: "startCallBack()")
    }
    
    class func stopTOCCallBack(_ webView: UIWebView) {
        webView.stringByEvaluatingJavaScript(from: "stopCallBack()")
    }
    
    class func getTableOfContents(_ webView: UIWebView) -> [HTMLHeading] {
        let jString = "getTableOfContents().headerObjects;"
        guard let elements = webView.context.evaluateScript(jString).toArray() as? [[String: String]] else {return [HTMLHeading]()}
        var headings = [HTMLHeading]()
        for element in elements {
            guard let heading = HTMLHeading(rawValue: element) else {continue}
            headings.append(heading)
        }
        return headings
    }
    
    class func getSnippet(_ webView: UIWebView) -> String? {
        guard let path = Bundle.main.path(forResource: "getSnippet", ofType: "js"),
            let jString = try? String(contentsOfFile: path),
            let snippet = webView.context.evaluateScript(jString).toString() else {return nil}
        return snippet == "null" ? nil : snippet
    }
}

extension UIWebView {
    var context: JSContext {
        return value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
    }
}
