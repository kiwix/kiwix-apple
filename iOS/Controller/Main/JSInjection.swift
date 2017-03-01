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
        guard let url = Bundle.main.url(forResource: "JSInject", withExtension: "js"),
            let jString = try? String(contentsOf: url) else {return}
        webView.stringByEvaluatingJavaScript(from: jString)
    }
    
    class func preventDefaultLongTap(webView: UIWebView) {
        let jString = "document.body.style.webkitTouchCallout='none';"
        webView.context.evaluateScript(jString)
    }
    
    class func adjustFontSizeIfNeeded(webView: UIWebView) {
        guard Preference.webViewZoomScale != 1 else {return}
        let jString = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", Preference.webViewZoomScale * 100)
        webView.stringByEvaluatingJavaScript(from: jString)
    }
    
    // MARK: - Attributes
    
    class func getTitle(from webView: UIWebView) -> String? {
        return webView.stringByEvaluatingJavaScript(from: "document.title")
    }
    
    class func getSnippet(from webView: UIWebView) -> String? {
        let jString = "snippet.parse();"
        guard let snippet = webView.context.evaluateScript(jString).toString() else {return nil}
        return snippet == "null" ? nil : snippet
    }
    
    // MARK: - Table of Contents
    
    class func startTOCCallBack(webView: UIWebView) {
        webView.stringByEvaluatingJavaScript(from: "tableOfContents.startCallBack()")
    }
    
    class func stopTOCCallBack(webView: UIWebView) {
        webView.stringByEvaluatingJavaScript(from: "tableOfContents.stopCallBack()")
    }
    
    class func getTableOfContents(webView: UIWebView) -> [HTMLHeading] {
        let jString = "tableOfContents.getHeadingObjects()"
        guard let elements = webView.context.evaluateScript(jString).toArray() as? [[String: Any]] else {return [HTMLHeading]()}
        var headings = [HTMLHeading]()
        for element in elements {
            guard let heading = HTMLHeading(rawValue: element) else {continue}
            headings.append(heading)
        }
        return headings
    }
    
    class func scrollToHeading(webView: UIWebView, index: Int) {
        webView.stringByEvaluatingJavaScript(from: "tableOfContents.scrollToView(\(index))")
    }
    
}

extension UIWebView {
    var context: JSContext {
        return value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
    }
}
