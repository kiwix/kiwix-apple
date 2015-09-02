//
//  ZimMultiReader.swift
//  Kiwix
//
//  Created by Chris Li on 8/12/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class ZimMultiReader: NSObject, DirectoryMonitorDelegate {
    static let sharedInstance = ZimMultiReader()
    let docDirMonitor = DirectoryMonitor(URL: NSURL(fileURLWithPath: Utilities.docDirPath()))
    
    override init() {
        super.init()
        updateCoredataDatabase()
        docDirMonitor.delegate = self
        docDirMonitor.startMonitoring()
    }
    
    deinit {
        docDirMonitor.stopMonitoring()
    }
    
    var allLocalZimFileReader: [String: ZimReader] = {
        var allLocalZimFile = [String: ZimReader]()
        if let fileNames = Utilities.contentsOfDocDir() {
            for fileName in fileNames {
                let url = NSURL(fileURLWithPath: Utilities.docDirPath()).URLByAppendingPathComponent(fileName)
                if let reader = ZimReader(ZIMFileURL: url) {
                    allLocalZimFile[reader.getID()] = reader
                }
            }
        }
        return allLocalZimFile
    }()
    
    var allLocalBooksInDataBase: [String: Book] = {
        if let allLocalBooks = Book.allLocalBooks((UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext) {
            return allLocalBooks
        } else {
            return [String: Book]()
        }
    }()
    
    // MARK: - Dynamic update

    func update() {
        updateReaderDic()
        updateCoredataDatabase()
    }
    
    func updateReaderDic() {
        if let fileNames = Utilities.contentsOfDocDir() {
            var currentZimFileIDInDocDir = [String]()
            
            // Loop through all files in Doc dir
            for fileName in fileNames {
                let fileURL = NSURL(fileURLWithPath: Utilities.docDirPath()).URLByAppendingPathComponent(fileName)
                if let reader = ZimReader(ZIMFileURL: fileURL) {
                    // If it is a zim file, update the new
                    let idString = reader.getID()
                    allLocalZimFileReader[idString] = reader
                    print ("zim file \(idString)'s reader is about to be added or replaced")
                    currentZimFileIDInDocDir.append(idString)
                }
            }
            
            // Find out id of files that are deleted
            let previouslyDeletedZimFileID: Array = {
                return Array(Set(allLocalZimFileReader.keys).subtract(currentZimFileIDInDocDir))
                }()
            
            // Remove reader of deleted file form reader dic
            for idString in previouslyDeletedZimFileID {
                print("zim file \(idString)'s reader is about to be deleted")
                allLocalZimFileReader[idString] = nil
            }
        }
    }
    
    func updateCoredataDatabase() {
        var currentLocalBooksInDataBase: [String: Book] = {
            if let allLocalBooks = Book.allLocalBooks((UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext) {
                return allLocalBooks
            } else {
                return [String: Book]()
            }
        }()
        
        let booksNoLongerAreLocal = Array(Set(currentLocalBooksInDataBase.keys).subtract(allLocalZimFileReader.keys))
        let booksNewlyBecomeLocal = Array(Set(allLocalZimFileReader.keys).subtract(currentLocalBooksInDataBase.keys))
        
        for idString in booksNoLongerAreLocal {
            if let book = currentLocalBooksInDataBase[idString] {
                book.downloadState = 0
                print("book \(idString) is set to online in database")
            }
        }
        
        for idString in booksNewlyBecomeLocal {
            let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
            if let book = Book.bookWithIDString(idString, context: managedObjectContext) {
                book.downloadState = 3
                currentLocalBooksInDataBase[idString] = book
            } else {
                if let reader = allLocalZimFileReader[idString], let metadata = bookMetadataFromReader(reader) {
                    if let book = Book.bookWithMetaDataDictionary(metadata, context: managedObjectContext) {
                        book.downloadState = 3
                        currentLocalBooksInDataBase[idString] = book
                    }
                } else {
                    print("Error: didn't find a reader with id \(idString) in all reader dic")
                }
            }
            
            if Preference.webViewHomePageBookID == nil {Preference.webViewHomePageBookID = idString; Preference.webViewHomePage = .MainPage}
        }
        
        allLocalBooksInDataBase = currentLocalBooksInDataBase
    }
    
    func bookMetadataFromReader(reader: ZimReader) -> [String: AnyObject]? {
        var metadata = [String: AnyObject]()
        
        if let idString = reader.getID() {metadata["id"] = idString}
        if let title = reader.getTitle() {metadata["title"] = title}
        if let description = reader.getDesc() {metadata["description"] = description}
        if let creator = reader.getCreator() {metadata["creator"] = creator}
        if let publisher = reader.getPublisher() {metadata["publisher"] = publisher}
        if let favicon = reader.getFavicon() {metadata["favicon"] = favicon}
        if let date = reader.getDate() {metadata["date"] = date}
        if let articleCount = reader.getArticleCount() {metadata["articleCount"] = articleCount}
        if let mediaCount = reader.getMediaCount() {metadata["mediaCount"] = mediaCount}
        if let fileSize = reader.getFileSize() {metadata["size"] = fileSize}
        
        if let langCode = reader.getLanguage() {
            metadata["language"] = Utilities.isoLangCodes()[langCode]
        }
        
        return metadata
    }
    
    // MARK: - Search
    
    func searchInAllZimFiles(searchTerm: String) -> [String] {
        return search(searchTerm, inZimFilesWithID: Array(allLocalZimFileReader.keys))
    }
    
    func search(searchTerm: String, inZimFilesWithID zimFileIDs: [String]) -> [String] {
        if searchTerm == "" {return [String]()}
        
        var allResults = [String]() // idString/articleTitle
        for idString in zimFileIDs {
            let firstCharRange = searchTerm.startIndex...searchTerm.startIndex
            let firstLetterCapitalisedSearchTerm = searchTerm.stringByReplacingCharactersInRange(firstCharRange, withString: searchTerm.substringWithRange(firstCharRange).capitalizedString)
            let searchTermVariations = Set([searchTerm, searchTerm.uppercaseString, searchTerm.lowercaseString, searchTerm.capitalizedString, firstLetterCapitalisedSearchTerm])
            
            let reader = allLocalZimFileReader[idString]
            var results = Set<String>()
            for searchTermVariation in searchTermVariations {
                results.unionInPlace(reader?.searchSuggestionsSmart(searchTermVariation) as! [String])
            }
            
            for result in results {
                allResults.append(idString.stringByAppendingFormat("/%@", result))
            }
        }
        
        allResults.sortInPlace { (item1, item2) -> Bool in
            let articleTitle1 = item1.componentsSeparatedByString("/")[1]
            let articleTitle2 = item2.componentsSeparatedByString("/")[1]
            return articleTitle1.caseInsensitiveCompare(articleTitle2) == .OrderedAscending
        }
        return allResults
    }
    
    // MARK: - Loading System
    
    func data(withZimFileID idString: String, contentURLString: String) -> [String: AnyObject]? {
        if let reader = allLocalZimFileReader[idString] {
            return reader.dataWithContentURLString(contentURLString) as? [String: AnyObject]
        } else {
            return nil
        }
    }
    
    func pageURLString(fromArticleTitle title: String, bookIdString idString: String) -> String? {
        if let reader = allLocalZimFileReader[idString] {
            return reader.pageURLFromTitle(title)
        } else {
            return nil
        }
    }
    
    func mainPageURLString(bookIdString idString: String) -> String? {
        if let reader = allLocalZimFileReader[idString] {
            return reader.mainPageURL()
        } else {
            return nil
        }
    }
    
    func randomPageURLString() -> (idString: String, contentURLString: String)? {
        var randomPageURLs = [(String, String)]()
        for (idString, reader) in allLocalZimFileReader {
            randomPageURLs.append((idString, reader.getRandomPageUrl()))
        }
        
        if randomPageURLs.count > 0 {
            let index = arc4random_uniform(UInt32(randomPageURLs.count))
            return randomPageURLs[Int(index)]
        } else {
            return nil
        }
    }
    
    // MARK: - DirectoryMonitorDelegate
    
    func directoryMonitorDidObserveChange() {
        self.update()
    }
}
