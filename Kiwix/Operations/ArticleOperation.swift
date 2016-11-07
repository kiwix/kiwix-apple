//
//  ArticleOperation.swift
//  Kiwix
//
//  Created by Chris Li on 9/7/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import Operations

class ArticleLoadOperation: Operation {
    let bookID: String?
    let path: String?
    let title: String?
    let url: URL?
    
    var animated = true
    
    init(url: URL) {
        self.bookID = nil
        self.path = nil
        self.title = nil
        self.url = url
        super.init()
    }
    
    init(bookID: String) {
        self.bookID = bookID
        self.path = nil
        self.title = nil
        self.url = nil
        super.init()
    }
    
    init(bookID: String, articlePath: String) {
        self.bookID = bookID
        self.path = articlePath
        self.title = nil
        self.url = nil
        super.init()
    }
    
    init(bookID: String, articleTitle: String) {
        self.bookID = bookID
        self.path = nil
        self.title = articleTitle
        self.url = nil
        super.init()
    }
    
    override func execute() {
        let controller = ((UIApplication.shared.delegate as! AppDelegate)
            .window?.rootViewController as! UINavigationController)
            .topViewController as! MainController
        guard let url: URL = {
            if let url = self.url { return url}
            if let bookID = bookID, let path = path { return URL(bookID: bookID, contentPath: path) }
            if let bookID = bookID, let title = title {
                guard let path = ZimMultiReader.shared.readers[bookID]?.pageURL(fromTitle: title) else {return nil}
                return URL(bookID: bookID, contentPath: path)
            }
            if let bookID = bookID {
                guard let reader = ZimMultiReader.shared.readers[bookID] else {return nil}
                let path = reader.mainPageURL()
                return URL(bookID: bookID, contentPath: path)
            }
            return nil
        }() else {
            // TODO - should produce error
            finish()
            return
        }

        let request = URLRequest(url: url)
        
        OperationQueue.main.addOperation {
            controller.hideSearch(animated: self.animated)
            controller.presentingViewController?.dismiss(animated: self.animated, completion: nil)
            if controller.traitCollection.horizontalSizeClass == .compact {controller.hideTableOfContentsController()}
            
            if controller.webView.request?.url != url {
                controller.webView.loadRequest(request)
            }
            
            self.finish()
        }
    }
}
