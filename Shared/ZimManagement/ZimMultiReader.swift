//
//  ZimMultiReader.swift
//  Kiwix
//
//  Created by Chris Li on 10/13/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import ProcedureKit

class ZimMultiReader: DirectoryMonitorDelegate{
    static let shared = ZimMultiReader()
    fileprivate(set) var readers = [ZimFileID: ZimReader]()
    private var montiors = [URL: DirectoryMonitor]()
    
    private let queue = ProcedureQueue()
    private weak var scanProcedure: Scan?
    
    private init() {}
    
    func scan(url: URL) {
        let scan = Scan(url: url)
        if let previous = scanProcedure { scan.addDependency(previous) }
        scanProcedure = scan
        queue.add(operation: scan)
    }
    
    // MARK: - Monitor
    
    func startMonitoring(url: URL) {
        let monitor = DirectoryMonitor(url: url)
        monitor.start()
        monitor.delegate = self
        montiors[url] = monitor
    }
    
    func stopMonitoring(url: URL) {
        montiors[url]?.stop()
        montiors[url] = nil
    }
    
    func directoryContentDidChange(url: URL) {
        scan(url: url)
    }
}

class Scan: Procedure {
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
        urls.forEach({ updateReader(url: $0) })
        updateDatabase()
        print(ZimMultiReader.shared.readers.count)
        finish()
    }
    
    func updateReader(url: URL) {
        var onDevice = [ZimFileID]()
        let urls = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])) ?? []
        for url in urls {
            guard url.pathExtension == "zim" || url.pathExtension == "zimaa",
                let reader = ZimReader(fileURL: url) else {return}
            onDevice.append(reader.id)
            if !ZimMultiReader.shared.readers.keys.contains(reader.id) {
                ZimMultiReader.shared.readers[reader.id] = reader
            }
        }
        
        Set(ZimMultiReader.shared.readers.keys).subtracting(onDevice).forEach({
            ZimMultiReader.shared.readers[$0] = nil
        })
    }
    
    func updateDatabase() {
        let context = CoreDataContainer.shared.newBackgroundContext()
        context.performAndWait {
            for (bookID, reader) in ZimMultiReader.shared.readers {
                if let book = Book.fetch(id: bookID, context: context) {
                    book.state = .local
                } else {
                    let book = Book(context: context)
                    book.id = reader.id
                    book.title = reader.title
                    book.desc = reader.bookDescription
                    book.pid = reader.name
                    book.date = reader.date
                    book.creator = reader.creator
                    book.publisher = reader.publisher
                    book.favIcon = reader.favicon
                    book.articleCount = reader.articleCount
                    book.mediaCount = reader.mediaCount
                    book.globalCount = reader.globalCount
                    
                    book.state = .local
                }
            }
            
            for book in Book.fetchLocal(in: context) {
                guard !ZimMultiReader.shared.readers.keys.contains(book.id) else {continue}
                if let _ = book.meta4URL {
                    book.state = .cloud
                } else {
                    context.delete(book)
                }
            }
            
            if context.hasChanges {
                try? context.save()
            }
        }
    }
}

typealias ZimFileID = String
