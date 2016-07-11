//
//  MainVCLoading.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import JavaScriptCore

extension MainVC {
       
    func load(url: NSURL?) {
        guard let url = url else {return}
        webView.hidden = false
        hideWelcome()
        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
    }
    
    func loadMainPage(id: ZimID) {
        guard let reader = ZimMultiReader.sharedInstance.readers[id] else {return}
        let mainPageURLString = reader.mainPageURL()
        let mainPageURL = NSURL.kiwixURLWithZimFileid(id, contentURLString: mainPageURLString)
        load(mainPageURL)
    }
    
    // MARK: - JS
    
    func getTableOfContents(webView: UIWebView) -> [HTMLHeading] {
        guard let context = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext,
              let path = NSBundle.mainBundle().pathForResource("getTableOfContents", ofType: "js"),
              let jString = Utilities.contentOfFileAtPath(path),
              let elements = context.evaluateScript(jString).toArray() as? [[String: String]] else {return [HTMLHeading]()}
        var headings = [HTMLHeading]()
        for element in elements {
            guard let heading = HTMLHeading(rawValue: element) else {continue}
            headings.append(heading)
        }
        return headings
    }
}

class HTMLHeading {
    let id: String
    let tagName: String
    let textContent: String
    let level: Int
    
    init?(rawValue: [String: String]) {
        let tagName = rawValue["tagName"] ?? ""
        self.id = rawValue["id"] ?? ""
        self.textContent = rawValue["textContent"] ?? ""
        self.tagName = tagName
        self.level = Int(tagName.stringByReplacingOccurrencesOfString("H", withString: "")) ?? -1
        
        if id == "" {return nil}
        if tagName == "" {return nil}
        if textContent == "" {return nil}
        if level == -1 {return nil}
    }
    
    var scrollToJavaScript: String {
        return "document.getElementById('\(id)').scrollIntoView();"
    }
}