//
//  Book.swift
//  Kiwix
//
//  Created by Chris Li on 11/10/16.
//  Copyright © 2016 Wikimedia CH. All rights reserved.
//

import ProcedureKit

/*
 Removes all zim file (single & chuncked) and the idx folder that belong to a book
 */

class DeleteBookFileOperation: Procedure {
    let zimID: ZimID
    
    init(zimID: ZimID) {
        self.zimID = zimID
        super.init()
    }
    
    override func execute() {
        guard let mainZimURL = ZimMultiReader.shared.readers[zimID]?.fileURL,
            let fileName = mainZimURL.pathComponents.last else {
            print("Cannot find reader")
            finish()
            return
        }
        
        let urls = URLSnapShot.zimFileURLsInDocDir().union(URLSnapShot.indexFolderURLsInDocDir())
        urls.forEach { (url) in
            guard url.pathComponents.last == fileName else {return}
            try? FileManager.default.removeItem(at: url)
        }
        
        finish()
    }
}
