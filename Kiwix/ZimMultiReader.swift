//
//  ZIMMultiReader.swift
//  Kiwix
//
//  Created by Chris on 12/19/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class ZIMMultiReader: NSObject, DirectoryMonitorDelegate {

    let monitor = DirectoryMonitor(URL: NSFileManager.docDirURL)
    var zimURLs = Set<NSURL>()
    var zimAdded = Set<NSURL>()
    var zimRemoved = Set<NSURL>()
    var readers = [String: ZimReader]()
    
    override init() {
        super.init()
        monitor.delegate = self
        monitor.startMonitoring()
        refresh()
    }
    
    deinit {
        monitor.stopMonitoring()
    }
    
    // MARK: - DirectoryMonitorDelegate
    
    func directoryMonitorDidObserveChange() {
        refresh()
    }
    
    // MARK: - Refresh
    
    func refresh() {
        let newZimURLs = Set(NSFileManager.zimFilesInDocDir())
        zimAdded = newZimURLs.subtract(zimURLs)
        zimRemoved = zimURLs.subtract(newZimURLs)
        removeOld()
        addNew()
        zimAdded.removeAll()
        zimRemoved.removeAll()
        zimURLs = newZimURLs
    }
    
    func removeOld() {
        for (id, reader) in readers {
            guard zimRemoved.contains(reader.fileURL) else {continue}
            readers[id] = nil
            
            guard let book = Book.fetch(id, context: UIApplication.appDelegate.managedObjectContext) else {return}
            if let _ = book.meta4URL {
                book.isLocal = false
            } else {
                UIApplication.appDelegate.managedObjectContext.deleteObject(book)
            }
            
        }
    }
    
    func addNew() {
        for url in zimAdded {
            let reader = ZimReader(ZIMFileURL: url)
            let id = reader.getID()
            readers[id] = reader
            
            let book: Book? = {
                let book = Book.fetch(id, context: UIApplication.appDelegate.managedObjectContext)
                return book ?? Book.add(reader.metaData, context: UIApplication.appDelegate.managedObjectContext)
            }()
            book?.isLocal = true
        }
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
