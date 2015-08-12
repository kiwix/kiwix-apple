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
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var urlSessionDic = [String: NSURLSession]()
    var booksDic = [String: Book]()
    var totalBytesWrittenDic: [String: Int64] = {
        if let allBooksWithBytesWritten = Book.allBooksWithBytesWritten((UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext) {
            var dictionary = [String: Int64]()
            for book in allBooksWithBytesWritten {
                dictionary[book.idString!] = book.totalBytesWritten!.longLongValue
            }
            return dictionary
        } else {
            print("Error: allBooksWithBytesWritten returned nil")
            return [String: Int64]()
        }
    }()
    
    deinit {
        for (idString, totalBytesWritten) in totalBytesWrittenDic {
            if let book = Book.bookWithIDString(idString, context: managedObjectContext) {
                book.totalBytesWritten = NSNumber(longLong: totalBytesWritten)
            } else {
                print("Error: didn't find book with id \(idString) in database")
            }
        }
    }
    
    func sessionWithIdentifier(identifier: String) -> NSURLSession {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifier)
        configuration.timeoutIntervalForRequest = 15.0
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }
    
    // MARK: Book Downloader
    
    func startDownloadBook(book: Book) {
        if let identifier = book.idString, meta4URL = book.meta4URL {
            let session = sessionWithIdentifier(identifier)
            let url = NSURL(string: meta4URL.stringByReplacingOccurrencesOfString(".meta4", withString: ""))
            session.downloadTaskWithURL(url!).resume()
            book.totalBytesWritten == 0.0
            urlSessionDic[identifier] = session
            booksDic[identifier] = book
            totalBytesWrittenDic[identifier] = 0
        } else {
            print("Download did not start successfully, either idstring or meta4url is missing")
        }
    }
    
    func cancelDownloadBook(book: Book) {
        if let session = urlSessionDic[book.idString!] {
            session.invalidateAndCancel()
        } else {
            print("Book cancel failed, didn't find the relevant url session in urlSessionDic")
        }
    }
    
    func pauseDownloadBook(book: Book) {
        if let session = urlSessionDic[book.idString!] {
            session.getTasksWithCompletionHandler({ (dataTasks, uploadTasks, downloadTasks) -> Void in
                for downloadTask in downloadTasks {
                    downloadTask.cancelByProducingResumeData({ (data) -> Void in
                        if let data = data {
                            Utilities.saveResumeData(data, book: book)
                            book.hasResumeData = true
                        }
                        session.invalidateAndCancel()
                    })
                }
            })
        } else {
            print("Pause book download failed, didn't find the relevant url session in urlSessionDic")
            totalBytesWrittenDic.removeValueForKey(book.idString!)
            Utilities.removeResumeData(book)
            book.totalBytesWritten = nil
        }
    }
    
    func resumeDownloadBook(book: Book) {
        if let resumeData = Utilities.readResumeData(book) {
            let session = sessionWithIdentifier(book.idString!)
            session.downloadTaskWithResumeData(resumeData)
            urlSessionDic[book.idString!] = session
            booksDic[book.idString!] = book
            totalBytesWrittenDic[book.idString!] = book.totalBytesWritten?.longLongValue
            book.hasResumeData = false
        } else {
            print("Resume book download failed, cannot read temp data of book \(book.idString!) successfully")
        }
    }
    
    // MARK: NSURLSessionTaskDelegate
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let error = error {
            if error.code == NSURLErrorCancelled {
                if let identifier = session.configuration.identifier, book = self.booksDic[identifier] {
                    if book.hasResumeData != true {
                        book.totalBytesWritten = nil
                        totalBytesWrittenDic.removeValueForKey(identifier)
                    }
                } else {
                    print("Error when processing successfully cancelled download task: either session identifier or fetched book is nil")
                }
            }
        }
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
        } else {
            print("Error: cannot get identifier from urlsession configuration")
        }
    }
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        
    }
    
    // MARK: NSURLSessionDownloadDelegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        if let identifier = session.configuration.identifier, book = self.booksDic[identifier] {
            book.totalBytesWritten = nil
            book.isLocal = true
            Utilities.moveDownloadedBook(book, toDocDirFromLocation: location)
        } else {
            print("Error: identifier or self.booksDic[identifier] is nil")
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let identifier = session.configuration.identifier!
        totalBytesWrittenDic[identifier] = totalBytesWritten
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let book = self.booksDic[identifier] {
                book.totalBytesWritten = NSNumber(longLong: totalBytesWritten)
            } else {
                print("Did not call back download progress: self.booksDic[identifier] is nil")
            }
        }
    }
}

protocol DownloaderDelegate {
    
}
