//
//  ArticleOperation.swift
//  Kiwix
//
//  Created by Chris Li on 9/7/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit
import CoreSpotlight
import CloudKit
import ProcedureKit

class ArticleLoadOperation: Procedure {
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
        let main = ((UIApplication.shared.delegate as! AppDelegate)
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
                guard let reader = ZimMultiReader.shared.readers[bookID],
                    let path = reader.mainPageURL() else {return nil}
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
            _ = main.searchBar.resignFirstResponder()
            
            main.presentedViewController?.dismiss(animated: true, completion: { 
                main.presentedViewController?.dismiss(animated: true, completion: nil)
            })
            main.hideWelcome()
            
            if main.traitCollection.horizontalSizeClass == .compact {
                main.hideTableOfContents(animated: true)
            }
            
            let webView = main.webView
            if webView?.request?.url != url {
                webView?.loadRequest(request)
            }
            
            self.finish()
        }
    }
}

class SpotlightIndexOperation: Procedure {
    init(url: URL) {
        assert(Thread.isMainThread, "This Operation can only be initialized in the main thread")
        super.init()
    }
    
    override func execute() {
        AppDelegate.persistentContainer.viewContext.performAndWait { 
            
        }
    }
}
