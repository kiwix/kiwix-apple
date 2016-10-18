//
//  JS.swift
//  Kiwix
//
//  Created by Chris Li on 9/9/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import JavaScriptCore

class JS {
    
    class func inject(webView: UIWebView) {
        let path = NSBundle.mainBundle().pathForResource("injection", ofType: "js")
        let jString = try? String(contentsOfFile: path!)
        webView.context.evaluateScript(jString!)
    }
    
    class func adjustFontSizeIfNeeded(webView: UIWebView) {
        guard Preference.webViewZoomScale != 100.0 else {return}
        let jString = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", Preference.webViewZoomScale)
        webView.stringByEvaluatingJavaScriptFromString(jString)
    }
    
    class func getTitle(from webView: UIWebView) -> String? {
        return webView.stringByEvaluatingJavaScriptFromString("document.title")
    }
    
    class func startTOCCallBack(webView: UIWebView) {
        webView.stringByEvaluatingJavaScriptFromString("startCallBack()")
    }
    
    class func stopTOCCallBack(webView: UIWebView) {
        webView.stringByEvaluatingJavaScriptFromString("stopCallBack()")
    }
    
    class func getTableOfContents(webView: UIWebView) -> [HTMLHeading] {
        let jString = "getTableOfContents().headerObjects;"
        guard let elements = webView.context.evaluateScript(jString).toArray() as? [[String: String]] else {return [HTMLHeading]()}
        var headings = [HTMLHeading]()
        for element in elements {
            guard let heading = HTMLHeading(rawValue: element) else {continue}
            headings.append(heading)
        }
        return headings
    }
    
    class func getSnippet(webView: UIWebView) -> String? {
        guard let path = NSBundle.mainBundle().pathForResource("getSnippet", ofType: "js"),
            let jString = try? String(contentsOfFile: path),
            let snippet = webView.context.evaluateScript(jString).toString() else {return nil}
        return snippet == "null" ? nil : snippet
    }
}

extension UIWebView {
    var context: JSContext {
        return valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as! JSContext
    }
}
