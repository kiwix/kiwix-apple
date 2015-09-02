//
//  Downloader.swift
//  Kiwix
//
//  Created by Chris Li on 8/5/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class Downloader: NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate{
    static let sharedInstance = Downloader()
    var delegate: DownloaderDelegate?
    var booksDic: [String: Book] = {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        if let bookDownloading = Book.allDownloadingBooks(managedObjectContext), let bookPaused = Book.allPausedBooks(managedObjectContext) {
            let books = bookPaused + bookDownloading
            var booksDic = [String: Book]()
            for book in books {
                booksDic[book.idString!] = book
                book.downloadState = 2
            }
            return booksDic
        } else {
            return [String: Book]()
        }
    }()
    
    lazy var totalBytesWrittenDic: [String: Int64] = {
        var totalBytesWrittenDic = [String: Int64]()
        for (idString, book) in self.booksDic {
            let totalBytesWritten = book.totalBytesWritten ?? 0.0
            totalBytesWrittenDic[book.idString!] = totalBytesWritten.longLongValue
        }
        return totalBytesWrittenDic
    }()
    
    lazy var urlSessionDic = [String: NSURLSession]()
    
    func saveTotalBytesWrittenToCoredata() {
        for (idString, totalBytesWritten) in totalBytesWrittenDic {
            if let book = booksDic[idString] {
                book.totalBytesWritten = NSNumber(longLong: totalBytesWritten)
            } else {
                print("Error: didn't find book with \(idString) in booksdic")
            }
        }
    }
    
    func rejoinSessionWithIdentifier(identifier: String) {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifier)
        let session = NSURLSession(configuration: configuration, delegate: Downloader.sharedInstance, delegateQueue: NSOperationQueue.mainQueue())
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        let book = Book.bookWithIDString(identifier, context: managedObjectContext)
        urlSessionDic[identifier] = session
        booksDic[identifier] = book
        totalBytesWrittenDic[identifier] = (book?.totalBytesWritten ?? 0.0).longLongValue
    }
    
    func sessionWithIdentifier(identifier: String) -> NSURLSession {
        if let session = urlSessionDic[identifier] {
            return session
        } else {
            let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifier)
            configuration.allowsCellularAccess = Preference.downloaderAllowCellularData
            configuration.timeoutIntervalForRequest = 15.0
            let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
            return session
        }
    }
    
    // MARK: Book Downloader
    
    func startDownloadBook(book: Book) {
        if let identifier = book.idString, meta4URL = book.meta4URL {
            // Ensure each book is only download once 
            if urlSessionDic[identifier] != nil {return}
            
            // Start book download
            let session = sessionWithIdentifier(identifier)
            let url = NSURL(string: meta4URL.stringByReplacingOccurrencesOfString(".meta4", withString: ""))
            session.downloadTaskWithURL(url!).resume()
            book.downloadState = 1
            totalBytesWrittenDic[identifier] = 0
            urlSessionDic[identifier] = session
            booksDic[identifier] = book
        } else {
            print("Download did not start successfully, either idstring or meta4url is missing")
        }
    }
    
    func cancelDownloadBook(book: Book) {
        if let session = urlSessionDic[book.idString!] {
            session.invalidateAndCancel()
        } else {
            Utilities.removeResumeData(book)
        }
        book.downloadState = 0
    }
    
    func pauseDownloadBook(book: Book) {
        if let session = urlSessionDic[book.idString!] {
            session.getTasksWithCompletionHandler({ (dataTasks, uploadTasks, downloadTasks) -> Void in
                if let downloadTask = downloadTasks.first {
                    downloadTask.cancelByProducingResumeData({ (data) -> Void in
                        if let data = data, totalBytesWritten = self.totalBytesWrittenDic[book.idString!] {
                            Utilities.saveResumeData(data, book: book)
                            book.totalBytesWritten = NSNumber(longLong: totalBytesWritten)
                            book.downloadState = 2
                        }
                        session.invalidateAndCancel()
                    })
                }
            })
        } else {
            print("Pause book download failed, didn't find the relevant url session in urlSessionDic")
            Utilities.removeResumeData(book)
            book.totalBytesWritten = nil
        }
    }
    
    func resumeDownloadBook(book: Book) {
        if let resumeData = Utilities.readResumeData(book) {
            let session = sessionWithIdentifier(book.idString!)
            session.downloadTaskWithResumeData(resumeData).resume()
            urlSessionDic[book.idString!] = session
            booksDic[book.idString!] = book
        } else {
            print("Resume book download failed, cannot read temp data of book \(book.idString!) successfully, restart download")
            startDownloadBook(book)
        }
    }
    
    // MARK: - NSURLSessionTaskDelegate
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        
    }
    
    // MARK: NSURLSessionDelegate
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        if let identifier = session.configuration.identifier {
            urlSessionDic.removeValueForKey(identifier)
            booksDic.removeValueForKey(identifier)
        } else {
            print("Error: cannot get identifier from urlsession configuration")
        }
    }
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        let idString = session.configuration.identifier!
        let book: Book? = {
            if let book = booksDic[idString] {
                return book
            } else {
                let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
                return Book.bookWithIDString(idString, context: managedObjectContext)
            }
        }()
        session.invalidateAndCancel()
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            Utilities.updateApplicationIconBadgeNumber()
            let localNotification = UILocalNotification()
            localNotification.alertBody = "Book " + (book?.title ?? "") + " has finished downloading!"
            localNotification.category = "KIWIX_BOOK_DOWNLOAD_FINISH"
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.userInfo = ["idString": idString]
            UIApplication.sharedApplication().presentLocalNotificationNow(localNotification) // Confirmed didFinishDownloadingToURL is called before this method
            
            // TODO: Use an array of closure to correctly call back handler for each urlsession
            if let handler = (UIApplication.sharedApplication().delegate as! AppDelegate).completionHandler {
                handler()
            }
        }
    }
    
    // MARK: NSURLSessionDownloadDelegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        if let identifier = session.configuration.identifier, book = self.booksDic[identifier] {
            Utilities.moveDownloadedBook(book, toDocDirFromLocation: location)
            booksDic.removeValueForKey(identifier)
            totalBytesWrittenDic.removeValueForKey(identifier)
            book.downloadState = 3
            session.invalidateAndCancel()
            if Preference.webViewHomePageBookID == nil {Preference.webViewHomePageBookID = book.idString; Preference.webViewHomePage = .MainPage}
        } else {
            print("Error:download finished but identifier or self.booksDic[identifier] is nil")
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        if let book = booksDic[session.configuration.identifier!] {
            book.downloadState = 1
            Utilities.removeResumeData(book)
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let identifier = session.configuration.identifier!
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let book = self.booksDic[identifier] {
                self.totalBytesWrittenDic[identifier] = totalBytesWritten
                self.delegate?.bookDownloadProgressUpdate(book, totalBytesWritten: totalBytesWritten)
            } else {
                print("Did not call back download progress: self.booksDic[identifier] is nil")
            }
        }
    }
}

protocol DownloaderDelegate {
    func bookDownloadProgressUpdate(book: Book, totalBytesWritten: Int64)
}
