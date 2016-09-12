//
//  ZimMultiReader.swift
//  Kiwix
//
//  Created by Chris on 12/19/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import CoreData
import Operations

class ZimMultiReader: NSObject, DirectoryMonitorDelegate {
    static let sharedInstance = ZimMultiReader()
    
    weak var delegate: ZimMultiReaderDelegate?
    private let monitor = DirectoryMonitor(URL: NSFileManager.docDirURL)
    
    private(set) var readers = [ZimID: ZimReader]()
    private var lastZimFileURLSnapshot = Set<NSURL>()
    private var lastIndexFolderURLSnapshot = Set<NSURL>()
    
    override init() {
        super.init()
        
        startScan()
        monitor.delegate = self
        monitor.startMonitoring()
    }
    
    deinit {
        monitor.stopMonitoring()
    }
    
    func startScan() {
        let operation = ScanLocalBookOperation(lastZimFileURLSnapshot: lastZimFileURLSnapshot, lastIndexFolderURLSnapshot: lastIndexFolderURLSnapshot)
        operation.addObserver(DidFinishObserver { (operation, errors) in
            guard let operation = operation as? ScanLocalBookOperation else {return}
            NSOperationQueue.mainQueue().addOperationWithBlock({ 
                self.lastZimFileURLSnapshot = operation.currentZimFileURLSnapshot
                self.lastIndexFolderURLSnapshot = operation.currentIndexFolderURLSnapshot
                
                guard operation.firstBookAdded else {return}
                self.delegate?.firstBookAdded()
            })
        })
        operation.queuePriority = .VeryHigh
        if readers.count == 0 { operation.qualityOfService = .UserInitiated }
        GlobalQueue.shared.add(scan: operation)
    }
    
    // MARK: - Reader Addition / Deletion
    
    func addReaders(urls: Set<NSURL>) {
        for url in urls {
            guard let reader = ZimReader(ZIMFileURL: url) else {continue}
            let id = reader.getID()
            readers[id] = reader
        }
    }
    
    func removeReaders(urls: Set<NSURL>) {
        for (id, reader) in readers {
            guard urls.contains(reader.fileURL) else {continue}
            readers[id] = nil
        }
    }
    
    // MARK: - DirectoryMonitorDelegate
    
    func directoryMonitorDidObserveChange() {
        startScan()
    }
    
    // MARK: - Loading System
    
    func data(id: String, contentURLString: String) -> [String: AnyObject]? {
        guard let reader = readers[id] else {return nil}
        return reader.dataWithContentURLString(contentURLString) as? [String: AnyObject]
    }
    
    func pageURLString(articleTitle: String, bookid id: String) -> String? {
        guard let reader = readers[id] else {return nil}
        return reader.pageURLFromTitle(articleTitle)
    }
    
    func mainPageURLString(bookid id: String) -> String? {
        guard let reader = readers[id] else {return nil}
        return reader.mainPageURL()
    }
    
    func randomPageURLString() -> (id: String, contentURLString: String)? {
        var randomPageURLs = [(String, String)]()
        for (id, reader) in readers{
            randomPageURLs.append((id, reader.getRandomPageUrl()))
        }
        
        guard randomPageURLs.count > 0 else {return nil}
        let index = arc4random_uniform(UInt32(randomPageURLs.count))
        return randomPageURLs[Int(index)]
    }
}

protocol ZimMultiReaderDelegate: class {
    func firstBookAdded()
}

