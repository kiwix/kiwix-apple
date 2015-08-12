//
//  LibraryRefresher.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class LibraryRefresher: NSObject, NSXMLParserDelegate {
    static let sharedInstance = LibraryRefresher()
    var delegate: LibraryRefresherDelegate?
    var isRetrieving = false
    var isProcessing = false
    var isoLangPairs = Utilities.isoLangCodes()
    var allOldOnlineBookIdInDatabase = [String]()
    var allNewOnlineBookIdInDatabase = [String]()
    
    lazy var privateManagedObjectContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        context.parentContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        return context
        }()
    
    func refreshLibraryIfNecessary() {
        if let lastLibraryRefreshTime = Preference.libraryLastRefreshTime {
            let libraryIsOld = -lastLibraryRefreshTime.timeIntervalSinceNow > Preference.libraryRefreshInterval
            let libraryIsRefreshing = LibraryRefresher.sharedInstance.isProcessing || LibraryRefresher.sharedInstance.isRetrieving
            let libraryAutoRefreshEnabled = !Preference.libraryAutoRefreshDisabled
            if libraryIsOld && !libraryIsRefreshing && libraryAutoRefreshEnabled {
                LibraryRefresher.sharedInstance.fetchBookData()
            }
        } else {
            // cannot find lastLibraryRefreshTime, i.e. have not refreshed, should start refresh
            LibraryRefresher.sharedInstance.fetchBookData()
        }
    }
    
    func fetchBookData() {
        if isRetrieving || isProcessing {return}
        if canConnectToInternet() {
            isRetrieving = true
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            self.delegate?.startedRetrievingLibrary()
            let libraryURL = NSURL(string: "http://www.kiwix.org/library.xml")
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithURL(libraryURL!, completionHandler: { (fetchedData, response, error) -> Void in
                self.isRetrieving = false
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                // Processing fetched data
                if let data = fetchedData {
                    self.isProcessing = true
                    self.delegate?.startedProcessingLibrary()
                    let xmlParser = NSXMLParser(data: data)
                    xmlParser.delegate = self
                    xmlParser.parse()
                } 
            })
            task.resume()
        } else {
            // Cannot connect to internet
            self.delegate?.failedWithErrorMessage("Cannot connect to the Internet.")
        }
    }
    
    func canConnectToInternet() -> Bool {
        return Reachability(hostName: "www.kiwix.org").currentReachabilityStatus() != NotReachable
    }
    
    // MARK: NSXMLParser Delegate
    
    func parserDidStartDocument(parser: NSXMLParser) {
        self.allOldOnlineBookIdInDatabase = Book.allOnlineBookIDs(self.privateManagedObjectContext)
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, var attributes attributeDict: [String : String]) {
        if elementName == "book" {
            if let langCode = attributeDict["language"] {
                if let language = self.isoLangPairs[langCode] {
                    attributeDict["language"] = language
                    Book.bookWithMetaDataDictionary(attributeDict, context: self.privateManagedObjectContext)
                    
                    let idString = attributeDict["id"]!
                    self.allNewOnlineBookIdInDatabase.append(idString)
                }
            }
        }
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        let idStringOfBookShouldBeDeleted = Set(self.allOldOnlineBookIdInDatabase).subtract(Set(self.allNewOnlineBookIdInDatabase))
        for idString in idStringOfBookShouldBeDeleted {
            let book = Book.bookWithIDString(idString, context: self.privateManagedObjectContext)
            print("about to delete \(book?.idString)")
            self.privateManagedObjectContext.deleteObject(book!)
        }
        
        if self.privateManagedObjectContext.hasChanges {
            do {
                try self.privateManagedObjectContext.save()
            } catch let error as NSError {
                // failure
                print("LibraryRefresher privateObjContext save failed: \(error.localizedDescription)")
            }
            
            dispatch_sync(dispatch_get_main_queue()) { () -> Void in
                let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
                do {
                    try managedObjectContext.save()
                } catch {
                    // failure
                    print("Main Queue managedObjectContext save failed.")
                }
            }
        }
        
        Preference.libraryLastRefreshTime = NSDate()
        self.isProcessing = false
        self.delegate?.finishedProcessingLibrary()
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        // Parsing Error
        self.delegate?.failedWithErrorMessage(parseError.userInfo.description)
    }
}

protocol LibraryRefresherDelegate {
    func startedRetrievingLibrary()
    func startedProcessingLibrary()
    func finishedProcessingLibrary()
    func failedWithErrorMessage(message: String)
}