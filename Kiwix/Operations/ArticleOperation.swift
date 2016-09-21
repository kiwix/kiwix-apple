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
    let url: NSURL?
    
    var animated = true
    
    init(url: NSURL) {
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
        let controller = ((UIApplication.sharedApplication().delegate as! AppDelegate)
            .window?.rootViewController as! UINavigationController)
            .topViewController as! MainController
        guard let url: NSURL = {
            if let url = self.url { return url}
            if let bookID = bookID, let path = path { return NSURL(bookID: bookID, contentPath: path) }
            if let bookID = bookID, let title = title {
                guard let path = ZimMultiReader.shared.readers[bookID]?.pageURLFromTitle(title) else {return nil}
                return NSURL(bookID: bookID, contentPath: path)
            }
            if let bookID = bookID {
                guard let reader = ZimMultiReader.shared.readers[bookID] else {return nil}
                let path = reader.mainPageURL()
                return NSURL(bookID: bookID, contentPath: path)
            }
            return nil
        }() else {
            // TODO - should produce error
            finish()
            return
        }

        let request = NSURLRequest(URL: url)
        
        NSOperationQueue.mainQueue().addOperationWithBlock {
            controller.hideSearch(animated: self.animated)
            controller.presentingViewController?.dismissViewControllerAnimated(self.animated, completion: nil)
            // hide toc
            
            guard controller.webView.request?.URL != url else {return}
            controller.webView.loadRequest(request)
            self.finish()
        }
    }
}
