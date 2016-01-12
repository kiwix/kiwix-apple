//
//  LibraryRefresher.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit
import CoreData

class LibraryRefresher: NSObject, NSXMLParserDelegate {
    weak var delegate: LibraryRefresherDelegate?
    var isRetrieving = false
    var isProcessing = false
    var oldBookIDs = [String]()
    var newBookIDs = [String]()
    private let reachability: Reachability? = {do {return try Reachability(hostname: "www.kiwix.org")} catch {return nil}}()
    
    lazy var privateManagedObjectContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        context.parentContext = UIApplication.appDelegate.managedObjectContext
        return context
    }()
    
    var canConnectToServer: Bool {
        guard let reachability = reachability else {return false}
        if Preference.libraryRefreshAllowCellularData {
            return reachability.currentReachabilityStatus == Reachability.NetworkStatus.NotReachable ? false : true
        } else {
            return reachability.currentReachabilityStatus == Reachability.NetworkStatus.ReachableViaWiFi ? true : false
        }
    }
    
    // MARK: - Refresher
    
    class var libraryIsOld: Bool {
        guard let lastLibraryRefreshTime = Preference.libraryLastRefreshTime else {return true}
        return -lastLibraryRefreshTime.timeIntervalSinceNow > Preference.libraryRefreshInterval
    }
    
    class var libraryAutoRefreshEnabled: Bool {
        return !Preference.libraryAutoRefreshDisabled
    }
    
    func refreshIfNeeded() {
        let libraryIsRefreshing = self.isProcessing || self.isRetrieving
        guard LibraryRefresher.libraryIsOld && !libraryIsRefreshing && LibraryRefresher.libraryAutoRefreshEnabled else {return}
        refresh()
    }
    
    func refresh() {
        guard !isRetrieving && !isProcessing else {return}
        guard canConnectToServer else {
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.delegate?.failedWithErrorMessage("Cannot connect to the Internet.")
            })
            return
        }
        isRetrieving = true
        UIApplication.networkTaskCount++
        self.delegate?.startedRetrievingLibrary()
        let libraryURL = NSURL(string: "http://www.kiwix.org/library.xml")
        let session = NSURLSession.sharedSession()
        session.configuration.allowsCellularAccess = Preference.libraryRefreshAllowCellularData
        let task = session.dataTaskWithURL(libraryURL!, completionHandler: { (fetchedData, response, error) -> Void in
            self.isRetrieving = false
            UIApplication.networkTaskCount--
            
            // Processing fetched data
            guard let data = fetchedData else {
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.delegate?.failedWithErrorMessage("There is an error with server, please try later.")
                })
                return
            }
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.isProcessing = true
                self.delegate?.startedProcessingLibrary()
            })
            let xmlParser = NSXMLParser(data: data)
            xmlParser.delegate = self
            xmlParser.parse()
        })
        task.resume()
    }
}

protocol LibraryRefresherDelegate: class {
    func startedRetrievingLibrary()
    func startedProcessingLibrary()
    func finishedProcessingLibrary()
    func failedWithErrorMessage(message: String)
}