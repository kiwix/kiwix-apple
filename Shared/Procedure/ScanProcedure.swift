//
//  ScanProcedure.swift
//  Kiwix
//
//  Created by Chris Li on 10/23/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import ProcedureKit

class ScanProcedure: Procedure {
    let urls: [URL]
    
    init(url: URL) {
        self.urls = [url]
        super.init()
    }
    
    init(urls: [URL]) {
        self.urls = urls
        super.init()
    }
    
    override func execute() {
        urls.forEach({ updateReader(dir: $0) })
//        updateDatabase()
        print("Scan Finished, number of readers: \(ZimMultiReader.shared.ids.count)")
        finish()
    }
    
    func updateReader(dir: URL) {
        let dirPathComponents = dir.pathComponents
        let urls = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])) ?? []
        
        for url in urls {
            let t = url.pathComponents
            ZimMultiReader.shared.addBook(url: url)
        }

        for url in ZimMultiReader.shared.urls {
            let parent: [String] = {
                var parent = url.pathComponents
                _ = parent.popLast()
                return parent
            }()
            
            guard parent == dirPathComponents else {continue}
            print(url)
            print(parent)
            
            if !urls.contains(url) {
                ZimMultiReader.shared.remove(url: url)
            }
        }
        
//        for url in urls {
//            guard url.pathExtension == "zim" || url.pathExtension == "zimaa",
//                let reader = ZimReader(fileURL: url) else {return}
//            onDevice.append(reader.id)
//            if !ZimMultiReader.shared.readers.keys.contains(reader.id) {
//                ZimMultiReader.shared.readers[reader.id] = reader
//            }
//        }
//
//        Set(ZimMultiReader.shared.readers.keys).subtracting(onDevice).forEach({
//            ZimMultiReader.shared.readers[$0] = nil
//        })
    }
    
//    func updateDatabase() {
//        let context = CoreDataContainer.shared.newBackgroundContext()
//        context.performAndWait {
//            for (bookID, reader) in ZimMultiReader.shared.readers {
//                if let book = Book.fetch(id: bookID, context: context) {
//                    book.state = .local
//                } else {
//                    let book = Book(context: context)
//                    book.id = reader.id
//                    book.title = reader.title
//                    book.desc = reader.bookDescription
//                    book.pid = reader.name
//                    book.date = reader.date
//                    book.creator = reader.creator
//                    book.publisher = reader.publisher
//                    book.favIcon = reader.favicon
//                    book.articleCount = reader.articleCount
//                    book.mediaCount = reader.mediaCount
//                    book.globalCount = reader.globalCount
//
//                    book.state = .local
//                }
//            }
//
//            for book in Book.fetchLocal(in: context) {
//                guard !ZimMultiReader.shared.readers.keys.contains(book.id) else {continue}
//                if let _ = book.meta4URL {
//                    book.state = .cloud
//                } else {
//                    context.delete(book)
//                }
//            }
//
//            if context.hasChanges {
//                try? context.save()
//            }
//        }
//    }
}

