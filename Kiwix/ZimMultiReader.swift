//
//  ZIMMultiReader.swift
//  Kiwix
//
//  Created by Chris on 12/19/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import CoreData

class ZIMMultiReader: NSObject, DirectoryMonitorDelegate {
    
    static let sharedInstance = ZIMMultiReader()
    private(set) var readers = [String: ZimReader]()
    let searchQueue = OperationQueue()
    
    private let monitor = DirectoryMonitor(URL: FileManager.docDirURL)
    private var zimURLs = Set<NSURL>()
    private var zimAdded = Set<NSURL>()
    private var zimRemoved = Set<NSURL>()
    private var indexFolders = Set<NSURL>()
    
    override init() {
        super.init()
        monitor.delegate = self
        monitor.startMonitoring()
    }
    
    deinit {
        monitor.stopMonitoring()
    }
    
    // MARK: - DirectoryMonitorDelegate
    
    func directoryMonitorDidObserveChange() {
        rescan()
    }
    
    // MARK: - Refresh
    
    func rescan() {
        /*
         If list of idx folders changes, reinitialize all zim readers, 
         because currently ZIMMultiReader cannot find out which ZimReader's index folder is added or deleted
         
         Note: when a idx folder is added, the content of that idx folder will not finish copying, which makes it meanless to detect idx folder addition. 
         Because, with a incompletely copied idx folder, the xapian initializer is guranteed to fail. So here only check for idx folder deletion. 
         If user added a idx folder, he or she needs to manaually call rescan.
         */
        let newIndexFolders = Set(indexFolderURLsInDocDir)
        let deletedIdxFolder = indexFolders.subtract(newIndexFolders)
        
        // Check for idx folder deletion
        if deletedIdxFolder.count > 0 {
            zimURLs.removeAll()
        }
        indexFolders = newIndexFolders
        
        // Below are the lines required when not considering idx folders, aka only detect zim files
        let newZimURLs = Set(zimFileURLsInDocDir)
        zimAdded = newZimURLs.subtract(zimURLs)
        zimRemoved = zimURLs.subtract(newZimURLs)
        removeOld()
        addNew()
        zimAdded.removeAll()
        zimRemoved.removeAll()
        zimURLs = newZimURLs
    }
    
    private func removeOld() {
        for (id, reader) in readers {
            guard zimRemoved.contains(reader.fileURL) else {continue}
            readers[id] = nil
            
            guard let book = Book.fetch(id, context: NSManagedObjectContext.mainQueueContext) else {return}
            if let _ = book.meta4URL {
                book.isLocal = false
            } else {
                NSManagedObjectContext.mainQueueContext.deleteObject(book)
            }
        }
    }
    
    private func addNew() {
        for url in zimAdded {
            guard let reader = ZimReader(ZIMFileURL: url) else {continue}
            let id = reader.getID()
            readers[id] = reader
            
            let book: Book? = {
                let book = Book.fetch(id, context: NSManagedObjectContext.mainQueueContext)
                return book ?? Book.add(reader.metaData, context: NSManagedObjectContext.mainQueueContext)
            }()
            book?.isLocal = true
            book?.hasIndex = reader.hasIndex()
            book?.hasPic = !reader.fileURL.absoluteString.containsString("nopic")
        }
    }
    
    private var zimFileURLsInDocDir: [NSURL] {
        let fileURLs = FileManager.contentsOfDirectory(FileManager.docDirURL) ?? [NSURL]()
        var zimURLs = [NSURL]()
        for url in fileURLs {
            do {
                var isDirectory: AnyObject? = nil
                try url.getResourceValue(&isDirectory, forKey: NSURLIsDirectoryKey)
                if let isDirectory = (isDirectory as? NSNumber)?.boolValue {
                    if !isDirectory {
                        guard let pathExtension = url.pathExtension?.lowercaseString else {continue}
                        guard pathExtension.containsString("zim") else {continue}
                        zimURLs.append(url)
                    }
                }
            } catch {
                continue
            }
        }
        return zimURLs
    }
    
    private var indexFolderURLsInDocDir: [NSURL] {
        let fileURLs = FileManager.contentsOfDirectory(FileManager.docDirURL) ?? [NSURL]()
        var folderURLs = [NSURL]()
        for url in fileURLs {
            do {
                var isDirectory: AnyObject? = nil
                try url.getResourceValue(&isDirectory, forKey: NSURLIsDirectoryKey)
                if let isDirectory = (isDirectory as? NSNumber)?.boolValue {
                    if isDirectory {
                        guard let pathExtension = url.pathExtension?.lowercaseString else {continue}
                        guard pathExtension == "idx" else {continue}
                        folderURLs.append(url)
                    }
                }
            } catch {
                continue
            }
        }
        return folderURLs
    }
}

extension ZimReader {
    var metaData: [String: AnyObject] {
        var metadata = [String: AnyObject]()
        
        if let id = getID() {metadata["id"] = id}
        if let title = getTitle() {metadata["title"] = title}
        if let description = getDesc() {metadata["description"] = description}
        if let creator = getCreator() {metadata["creator"] = creator}
        if let publisher = getPublisher() {metadata["publisher"] = publisher}
        if let favicon = getFavicon() {metadata["favicon"] = favicon}
        if let date = getDate() {metadata["date"] = date}
        if let articleCount = getArticleCount() {metadata["articleCount"] = articleCount}
        if let mediaCount = getMediaCount() {metadata["mediaCount"] = mediaCount}
        if let fileSize = getFileSize() {metadata["size"] = fileSize}
        if let langCode = getLanguage() {metadata["language"] = langCode}
        
        return metadata
    }
}

typealias ZIMID = String

class SearchResult: CustomStringConvertible {
    let title: String
    let path: String
    let bookID: ZIMID
    let snippet: String?
    
    let probability: Double? // range: 0.0 - 1.0
    let distance: Int // Levenshtein distance, non negative integer
    private(set) lazy var score: Double = {
        if let probability = self.probability {
            return WeightFactor.calculate(probability) * Double(self.distance)
        } else {
            return Double(self.distance)
        }
    }()
    
    init?(rawResult: [String: AnyObject]) {
        let title = (rawResult["title"] as? String) ?? ""
        let path = (rawResult["path"] as? String) ?? ""
        let bookID = (rawResult["bookID"] as? ZIMID) ?? ""
        let snippet = rawResult["snippet"] as? String
        
        let distance = (rawResult["distance"]as? NSNumber)?.integerValue ?? title.characters.count
        let probability: Double? = {
            if let probability = (rawResult["probability"] as? NSNumber)?.doubleValue {
                return probability / 100.0
            } else {
                return nil
            }
        }()
        
        self.title = title
        self.path = path
        self.bookID = bookID
        self.snippet = snippet
        self.probability = probability
        self.distance = distance
        
        if title == "" || path == "" || bookID == "" {return nil}
    }
    
    var description: String {
        var parts = [bookID, title]
        if let probability = probability {parts.append("\(probability)%")}
        parts.append("dist: \(distance)")
        return parts.joinWithSeparator(", ")
    }
}
