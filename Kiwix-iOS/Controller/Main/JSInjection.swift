//
//  JSInjection.swift
//  Kiwix
//
//  Created by Chris Li on 9/9/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import JavaScriptCore

class JSInjection {
    
    class func inject(webView: UIWebView) {
        let context = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext
        let path = NSBundle.mainBundle().pathForResource("injection", ofType: "js")
        let jString = try? String(contentsOfFile: path!)
        context?.evaluateScript(jString!)
    }
    
    class func adjustFontSizeIfNeeded(webView: UIWebView) {
        guard Preference.webViewZoomScale != 100.0 else {return}
        let jString = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", Preference.webViewZoomScale)
        webView.stringByEvaluatingJavaScriptFromString(jString)
    }
    
    class func getTitle(from webView: UIWebView) -> String? {
        return webView.stringByEvaluatingJavaScriptFromString("document.title")
    }
    
    class func getTableOfContents(webView: UIWebView) -> [HTMLHeading] {
        let jString = "(new TableOfContents()).headerObjects;"
        guard let context = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext,
            let elements = context.evaluateScript(jString).toArray() as? [[String: String]] else {return [HTMLHeading]()}
        var headings = [HTMLHeading]()
        for element in elements {
            guard let heading = HTMLHeading(rawValue: element) else {continue}
            headings.append(heading)
        }
        return headings
    }
    
    class func getSnippet(webView: UIWebView) -> String? {
        guard let context = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext,
            let path = NSBundle.mainBundle().pathForResource("getSnippet", ofType: "js"),
            let jString = try? String(contentsOfFile: path),
            let snippet = context.evaluateScript(jString).toString() else {return nil}
        return snippet == "null" ? nil : snippet
    }
}
