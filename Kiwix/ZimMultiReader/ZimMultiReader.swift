//
//  ZimMultiReader.swift
//  Kiwix
//
//  Created by Chris on 12/19/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import CoreData
import ProcedureKit

class ZimMultiReader: NSObject, DirectoryMonitorDelegate {
    static let shared = ZimMultiReader()
    
    weak var delegate: ZimMultiReaderDelegate?
    fileprivate let monitor = DirectoryMonitor(URL: FileManager.docDirURL)
    
    fileprivate(set) var readers = [ZimID: ZimReader]()
    fileprivate(set) var pidMap = [String: String]() // PID: ID
    fileprivate var lastZimFileURLSnapshot = Set<URL>()
    fileprivate var lastIndexFolderURLSnapshot = Set<URL>()
    
    override init() {
        super.init()
        monitor.delegate = self
        monitor.startMonitoring()
    }
    
    deinit {
        monitor.stopMonitoring()
    }
    
    func startScan() {
//        let operation = ScanLocalBookOperation(lastZimFileURLSnapshot: lastZimFileURLSnapshot as Set<NSURL>, lastIndexFolderURLSnapshot: lastIndexFolderURLSnapshot as Set<NSURL>)
//        operation.addObserver(DidFinishObserver { (operation, errors) in
//            guard let operation = operation as? ScanLocalBookOperation else {return}
//            NSOperationQueue.mainQueue().addOperationWithBlock({ 
//                self.lastZimFileURLSnapshot = operation.currentZimFileURLSnapshot
//                self.lastIndexFolderURLSnapshot = operation.currentIndexFolderURLSnapshot
//                
//                guard operation.firstBookAdded else {return}
//                self.delegate?.firstBookAdded()
//            })
//        })
//        operation.queuePriority = .veryHigh
//        if readers.count == 0 { operation.qualityOfService = .userInteractive }
//        GlobalQueue.shared.add(scan: operation)
    }
    
    // MARK: - Reader Addition / Deletion
    
    func addReaders(_ urls: Set<URL>) {
        for url in urls {
            guard let reader = ZimReader(zimFileURL: url) else {continue}
            let id = reader.getID()
            readers[id!] = reader
        }
    }
    
    func removeReaders(_ urls: Set<URL>) {
        for (id, reader) in readers {
            guard urls.contains(reader.fileURL) else {continue}
            readers[id] = nil
        }
    }
    
    func producePIDMap() {
        pidMap.removeAll()
        var map = [String: [ZimReader]]() // PID: [ZimReader]
        for (_, reader) in readers {
            guard let pid = reader.getName(), pid != "" else {continue}
            var readers = map[pid] ?? [ZimReader]()
            readers.append(reader)
            map[pid] = readers
        }
        for (pid, readers) in map {
            guard let reader = readers.sorted(by: { $0.getDate().caseInsensitiveCompare($1.getDate()) == .orderedAscending }).first,
                let id = reader.getID() else {continue}
            pidMap[pid] = id
        }
    }
    
    // MARK: - DirectoryMonitorDelegate
    
    func directoryMonitorDidObserveChange() {
        startScan()
    }
    
    // MARK: - Loading System
    
    func data(_ id: String, contentURLString: String) -> [String: AnyObject]? {
        guard let reader = readers[id] else {return nil}
        return reader.data(withContentURLString: contentURLString) as? [String: AnyObject]
    }
    
    func pageURLString(_ articleTitle: String, bookid id: String) -> String? {
        guard let reader = readers[id] else {return nil}
        return reader.pageURL(fromTitle: articleTitle)
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

