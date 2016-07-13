//
//  ZimMultiReader.swift
//  Kiwix
//
//  Created by Chris on 12/19/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import CoreData
import PSOperations

class ZimMultiReader: NSObject, DirectoryMonitorDelegate {
    static let sharedInstance = ZimMultiReader()
    
    weak var delegate: ZimMultiReaderDelegate?
    private weak var scanOperation: ScanLocalBookOperation?
    
    let searchQueue = OperationQueue()
    private(set) var isScanning = false
    private(set) var readers = [ZimID: ZimReader]()
    private let monitor = DirectoryMonitor(URL: FileManager.docDirURL)
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
        isScanning = true
        let scanOperation = ScanLocalBookOperation(lastZimFileURLSnapshot: lastZimFileURLSnapshot, lastIndexFolderURLSnapshot: lastIndexFolderURLSnapshot) { (currentZimFileURLSnapshot, currentIndexFolderURLSnapshot, firstBookAdded) in
            self.lastZimFileURLSnapshot = currentZimFileURLSnapshot
            self.lastIndexFolderURLSnapshot = currentIndexFolderURLSnapshot
            self.isScanning = false
            if firstBookAdded {
                self.delegate?.firstBookAdded()
            }
        }
        GlobalOperationQueue.sharedInstance.addOperation(scanOperation)
        self.scanOperation = scanOperation
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
    
    // MARK: - Search
    
    func startSearch(searchOperation: SearchOperation) {
        if let scanOperation = scanOperation {
            searchOperation.addDependency(scanOperation)
        }
        searchQueue.addOperation(searchOperation)
    }
    
    // MARK: Search (Old)
    
    func search(searchTerm: String, zimFileID: String) -> [(id: String, articleTitle: String)] {
        var resultTuples = [(id: String, articleTitle: String)]()
        let firstCharRange = searchTerm.startIndex...searchTerm.startIndex
        let firstLetterCapitalisedSearchTerm = searchTerm.stringByReplacingCharactersInRange(firstCharRange, withString: searchTerm.substringWithRange(firstCharRange).capitalizedString)
        let searchTermVariations = Set([searchTerm, searchTerm.uppercaseString, searchTerm.lowercaseString, searchTerm.capitalizedString, firstLetterCapitalisedSearchTerm])
        
        let reader = readers[zimFileID]
        var results = Set<String>()
        for searchTermVariation in searchTermVariations {
            guard let result = reader?.searchSuggestionsSmart(searchTermVariation) as? [String] else {continue}
            results.unionInPlace(result)
        }
        
        for result in results {
            resultTuples.append((id: zimFileID, articleTitle: result))
        }
        
        return resultTuples
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

