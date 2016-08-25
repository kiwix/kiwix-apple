//
//  DownloadBookOperation.swift
//  Kiwix
//
//  Created by Chris Li on 8/25/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import Operations

class DownloadBookOperation: Operation {
    
    private let bookID: String
    private let url: NSURL
    private let spaceState: BookSpaceState
    
    init?(book: Book) {
        assert(NSThread.isMainThread(), "DownloadBookOperation has to be initialized on main thread")
        assert(book.managedObjectContext === NSManagedObjectContext.mainQueueContext, "DownloadBookOperation has to be initialized with a Book managed object belongs to the main queue context")
        self.bookID = book.id ?? ""
        self.url = book.url ?? NSURL()
        self.spaceState = book.spaceState
        
        super.init()
        
        if self.bookID == "" || self.url.absoluteString == "" {return nil}
    }
    
    override func execute() {
        defer { finish() }
        
        switch spaceState {
        case .Caution:
            print("caution")
        case .NotEnough:
            print("not enough")
        default:
            print("down")
        }
    }
}
