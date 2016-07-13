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
    let searchQueue = OperationQueue()
    weak var delegate: ZimMultiReaderDelegate?
    
    private(set) var readers = [ZimID: ZimReader]() {
        didSet {
            if readers.count == 1 {
                guard let id = readers.keys.first else {return}
                delegate?.firstBookAdded(id)
            }
        }
    }
    
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
        scan()
    }
    
    // MARK: - Scan
    
    func scan() {
        /*
         If list of idx folders changes, reinitialize all zim readers, 
         because currently ZimMultiReader cannot find out which ZimReader's index folder is added or deleted
         
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
    
    // MARK: - Search
    
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
    func firstBookAdded(id: ZimID)
}

