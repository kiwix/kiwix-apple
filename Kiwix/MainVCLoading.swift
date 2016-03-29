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
        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
    }
    
    func loadMainPage(book: Book) {
        guard let id = book.id else {return}
        guard let reader = UIApplication.multiReader.readers[id] else {return}
        let mainPageURLString = reader.mainPageURL()
        let mainPageURL = NSURL.kiwixURLWithZimFileid(id, contentURLString: mainPageURLString)
        load(mainPageURL)
    }
    
    // MARK: - JS
    
    func getTOC(webView: UIWebView) {
        guard let context = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext else {return}
        guard let path = NSBundle.mainBundle().pathForResource("getTableOfContents", ofType: "js") else {return}
        guard let jString = Utilities.contentOfFileAtPath(path) else {return}
        let value: JSValue = context.evaluateScript(jString)
        print(value.toArray())
    }
}