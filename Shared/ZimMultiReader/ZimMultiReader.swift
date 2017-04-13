//
//  ZimMultiReader.swift
//  Kiwix
//
//  Created by Chris on 12/19/15.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import ProcedureKit

typealias ZimID = String
typealias ArticlePath = String

class ZimMultiReader: NSObject, DirectoryMonitorDelegate {
    static let shared = ZimMultiReader()
    
    weak var delegate: ZimMultiReaderDelegate?
    private let docDirURL: URL
    private let monitor: DirectoryMonitor
    
    private(set) var readers = [ZimID: ZimReader]()
    private(set) var pidMap = [String: ZimID]() // PID: ID
    private var urlSnapShot = URLSnapShot()
    
    private override init() {
        docDirURL = (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false))!
        monitor = DirectoryMonitor(URL: docDirURL)
        super.init()
        monitor.delegate = self
        monitor.startMonitoring()
    }
    
    deinit {
        monitor.stopMonitoring()
    }
    
    func startScan() {
        let operation = ScanLocalBookOperation(snapshot: urlSnapShot)
        operation.add(observer: DidFinishObserver{ (operation, errors) in
            guard let operation = operation as? ScanLocalBookOperation else {return}
            OperationQueue.main.addOperation({
                self.urlSnapShot = operation.newSnapshot
                guard operation.firstBookAdded else {return}
                self.delegate?.firstBookAdded()
            })
        })
        operation.queuePriority = .veryHigh
        if readers.count == 0 { operation.qualityOfService = .userInteractive }
        GlobalQueue.shared.add(scanOperation: operation)
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

struct URLSnapShot {
    let zimFile: Set<URL>
    let indexFolder: Set<URL>
    
    init() {
        self.zimFile = URLSnapShot.zimFileURLsInDocDir()
        self.indexFolder = URLSnapShot.indexFolderURLsInDocDir()
    }
    
    private static func getDocDirContents() -> [URL] {
        let docDirURL = (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false))!
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]
        let urls = try? FileManager.default.contentsOfDirectory(at: docDirURL, includingPropertiesForKeys: nil, options: options)
        return urls ?? [URL]()
    }
    
    static func - (lhs: URLSnapShot, rhs: URLSnapShot) -> (zimFiles: Set<URL>, indexFolders: Set<URL>) {
        return (lhs.zimFile.subtracting(rhs.zimFile), lhs.indexFolder.subtracting(rhs.indexFolder))
    }
    
    static func zimFileURLsInDocDir() -> Set<URL> {
        var urls = getDocDirContents()
        let keys = [URLResourceKey.isDirectoryKey]
        urls = urls.filter { (url) -> Bool in
            guard let values = try? (url as NSURL).resourceValues(forKeys: keys),
                let isDirectory = (values[URLResourceKey.isDirectoryKey] as? NSNumber)?.boolValue, isDirectory == false else {return false}
            let pathExtension = url.pathExtension.lowercased()
            guard pathExtension.contains("zim") else {return false}
            return true
        }
        return Set(urls)
    }
    
    static func indexFolderURLsInDocDir() -> Set<URL> {
        var urls = getDocDirContents()
        let keys = [URLResourceKey.isDirectoryKey]
        urls = urls.filter { (url) -> Bool in
            guard let values = try? (url as NSURL).resourceValues(forKeys: keys),
                let isDirectory = (values[URLResourceKey.isDirectoryKey] as? NSNumber)?.boolValue, isDirectory == true else {return false}
            let pathExtension = url.pathExtension.lowercased()
            guard pathExtension == "idx" else {return false}
            return true
        }
        return Set(urls)
    }
}

protocol ZimMultiReaderDelegate: class {
    func firstBookAdded()
}

extension ZimReader {
    var metaData: [String: String] {
        var metadata = [String: String]()
        
        metadata["id"] = getID()
        metadata["title"] = getTitle()
        metadata["description"] = getDesc()
        metadata["creator"] = getCreator()
        metadata["publisher"] = getPublisher()
        metadata["favicon"] = getFavicon()
        metadata["date"] = getDate()
        metadata["articleCount"] = getArticleCount()
        metadata["mediaCount"] = getMediaCount()
        metadata["size"] = getFileSize()
        metadata["language"] = getLanguage()
        
        return metadata
    }
}

