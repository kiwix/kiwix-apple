//
//  LibraryRefresherXMLParser.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

extension LibraryRefresher {
    
    // MARK: NSXMLParser Delegate
    
    func parserDidStartDocument(parser: NSXMLParser) {
        oldBookIDs = Book.fetchAll(privateManagedObjectContext).map({$0.id ?? ""})
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, var attributes attributeDict: [String : String]) {
        guard elementName == "book" else {return}
        guard let id = attributeDict["id"] else {return}
        
        if !oldBookIDs.contains(id) {
            Book.add(attributeDict, context: privateManagedObjectContext)
        }
        newBookIDs.append(id)
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        let booksToDelete = Set(oldBookIDs).subtract(Set(newBookIDs))
        for id in booksToDelete {
            guard let book = Book.fetch(id, context: self.privateManagedObjectContext) else {continue}
            print("LibraryRefresher is about to delete book: \(book.id)")
            privateManagedObjectContext.deleteObject(book)
        }
        
        saveManagedObjectContexts()
        Preference.libraryLastRefreshTime = NSDate()
        isProcessing = false
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.delegate?.finishedProcessingLibrary()
        }
        cleanUpAfterParse()
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        isProcessing = false
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.delegate?.failedWithErrorMessage(parseError.localizedDescription)
        }
        saveManagedObjectContexts()
        cleanUpAfterParse()
    }
    
    // MARK: - Tools
    
    func saveManagedObjectContexts() {
        if privateManagedObjectContext.hasChanges {
            do {
                try privateManagedObjectContext.save()
            } catch let error as NSError {
                print("LibraryRefresher privateObjContext save failed: \(error.localizedDescription)")
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                let managedObjectContext = UIApplication.appDelegate.managedObjectContext
                do {
                    try managedObjectContext.save()
                } catch let error as NSError {
                    print("Main Queue managedObjectContext save failed: \(error.localizedDescription)")
                }
            })
        }
    }
    
    func cleanUpAfterParse() {
        newBookIDs = [String]()
        oldBookIDs = [String]()
    }
}