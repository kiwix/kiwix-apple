//
//  DownloadBookOperation.swift
//  Kiwix
//
//  Created by Chris Li on 8/25/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import Operations

class DownloadBookOperation: URLSessionDownloadTaskOperation {
    let bookID: String?
    let progress: DownloadProgress
    
    override init(downloadTask: URLSessionDownloadTask) {
        progress = DownloadProgress(completedUnitCount: downloadTask.countOfBytesReceived, totalUnitCount: downloadTask.countOfBytesExpectedToReceive)
        bookID = downloadTask.taskDescription
        super.init(downloadTask: downloadTask)
        name = downloadTask.taskDescription
        
        if UIApplication.shared.applicationState == .active,
            let url = downloadTask.originalRequest?.url {
            addCondition(ReachabilityCondition(url: url, connectivity: .ViaWiFi))
        }
        
        // Update Coredata
        let context = NSManagedObjectContext.mainQueueContext
        context.performAndWait {
            guard let bookID = self.bookID,
                let book = Book.fetch(bookID, context: context),
                let downloadTask = DownloadTask.addOrUpdate(book, context: context) else {return}
            book.state = .downloading
            downloadTask.state = .queued
            
            // Overwrite progress
            self.progress.completedUnitCount = book.downloadTask?.totalBytesWritten ?? 0
            self.progress.totalUnitCount = book.fileSize
        }
    }
    
    convenience init?(bookID: String, resumeData: Data) {
        if #available(iOS 10.0, *) {
            guard let data = DownloadBookOperation.correctFuckingResumeData(resumeData) else {return nil}
            let downloadTask = Network.shared.session.downloadTask(withResumeData: data)
            downloadTask.taskDescription = bookID
            self.init(downloadTask: downloadTask)
        } else {
            let downloadTask = Network.shared.session.downloadTask(withResumeData: resumeData)
            downloadTask.taskDescription = bookID
            self.init(downloadTask: downloadTask)
        }
    }
    
    convenience init?(bookID: String) {
        let context = NSManagedObjectContext.mainQueueContext
        guard let book = Book.fetch(bookID, context: context),
            let url = book.url else { return nil }

        let task = Network.shared.session.downloadTask(with: url)
        task.taskDescription = bookID
        self.init(downloadTask: task)
    }
    
    override func operationDidCancel() {
        // Not Reachable
        if let error = errors.first as? Operations.ReachabilityCondition.Error, error == .NotReachable {
            return
        }
        
        // Update Core Data
        if produceResumeData {
            let context = NSManagedObjectContext.mainQueueContext
            context.performAndWait({ 
                guard let bookID = self.bookID,
                    let book = Book.fetch(bookID, context: context) else {return}
                book.state = .downloading
            })
        } else {
            let context = NSManagedObjectContext.mainQueueContext
            context.performAndWait({
                guard let bookID = self.bookID,
                    let book = Book.fetch(bookID, context: context) else {return}
                book.state = .cloud
                
                guard let downloadTask = book.downloadTask else {return}
                context.delete(downloadTask)
            })
        }
        
        // URLSessionDelegate save resume data and update downloadTask
    }
    
    // MARK: - Helper
    
    fileprivate class func correctFuckingResumeData(_ data: Data?) -> Data? {
        let kResumeCurrentRequest = "NSURLSessionResumeCurrentRequest"
        let kResumeOriginalRequest = "NSURLSessionResumeOriginalRequest"
        
        guard let data = data, let resumeDictionary = (try? PropertyListSerialization.propertyList(from: data, options: [.mutableContainersAndLeaves], format: nil)) as? NSMutableDictionary else {
            return nil
        }
        
        resumeDictionary[kResumeCurrentRequest] = correctFuckingRequestData(resumeDictionary[kResumeCurrentRequest] as? Data)
        resumeDictionary[kResumeOriginalRequest] = correctFuckingRequestData(resumeDictionary[kResumeOriginalRequest] as? Data)
        
        let result = try? PropertyListSerialization.data(fromPropertyList: resumeDictionary, format: PropertyListSerialization.PropertyListFormat.xml, options: PropertyListSerialization.WriteOptions())
        return result
    }
    
    fileprivate class func correctFuckingRequestData(_ data: Data?) -> Data? {
        guard let data = data else {
            return nil
        }
        if NSKeyedUnarchiver.unarchiveObject(with: data) != nil {
            return data
        }
        guard let archive = (try? PropertyListSerialization.propertyList(from: data, options: [.mutableContainersAndLeaves], format: nil)) as? NSMutableDictionary else {
            return nil
        }
        // Rectify weird __nsurlrequest_proto_props objects to $number pattern
        var k = 0
        while archive["$objects"]?[1].object(forKey: "$\(k)") != nil {
            k += 1
        }
        var i = 0
        while archive["$objects"]?[1].object(forKey: "__nsurlrequest_proto_prop_obj_\(i)") != nil {
            let arr = archive["$objects"] as? NSMutableArray
            if let dic = arr?[1] as? NSMutableDictionary, let obj = dic["__nsurlrequest_proto_prop_obj_\(i)"] {
                dic.setObject(obj, forKey: "$\(i + k)" as NSCopying)
                dic.removeObject(forKey: "__nsurlrequest_proto_prop_obj_\(i)")
                arr?[1] = dic
                archive["$objects"] = arr
            }
            i += 1
        }
        if archive["$objects"]?[1]["__nsurlrequest_proto_props"] != nil {
            let arr = archive["$objects"] as? NSMutableArray
            if let dic = arr?[1] as? NSMutableDictionary, let obj = dic["__nsurlrequest_proto_props"] {
                dic.setObject(obj, forKey: "$\(i + k)" as NSCopying)
                dic.removeObject(forKey: "__nsurlrequest_proto_props")
                arr?[1] = dic
                archive["$objects"] = arr
            }
        }
        // Rectify weird "NSKeyedArchiveRootObjectKey" top key to NSKeyedArchiveRootObjectKey = "root"
        if archive["$top"]?["NSKeyedArchiveRootObjectKey"] != nil {
            (archive["$top"]? as AnyObject).set(archive["$top"]?["NSKeyedArchiveRootObjectKey"], forKey: NSKeyedArchiveRootObjectKey)
            (archive["$top"]? as AnyObject).removeObject(forKey: "NSKeyedArchiveRootObjectKey")
        }
        // Re-encode archived object
        let result = try? PropertyListSerialization.data(fromPropertyList: archive, format: PropertyListSerialization.PropertyListFormat.binary, options: PropertyListSerialization.WriteOptions())
        return result
    }
}

class RemoveBookOperation: Operation {
    let bookID: String
    
    init(bookID: String) {
        self.bookID = bookID
        super.init()
    }
    
    override func execute() {
        let context = NSManagedObjectContext.mainQueueContext
        context.performAndWait {
            guard let zimFileURL = ZimMultiReader.shared.readers[self.bookID]?.fileURL else {return}
            _ = try? FileManager.default.removeItem(at: zimFileURL)
            
            // Core data is updated by scan book operation
            // Article removal is handled by cascade relationship
            
            guard let idxFolderURL = ZimMultiReader.shared.readers[self.bookID]?.idxFolderURL else {return}
            _ = try? FileManager.default.removeItem(at: idxFolderURL)
        }
        finish()
    }
}

class PauseBookDwonloadOperation: Operation {
    let bookID: String
    
    init(bookID: String) {
        self.bookID = bookID
        super.init()
    }
    
    override func execute() {
        Network.shared.operations[bookID]?.cancel(produceResumeData: true)
        finish()
    }
}

class ResumeBookDwonloadOperation: Operation {
    let bookID: String
    
    init(bookID: String) {
        self.bookID = bookID
        super.init()
        name = "Resume Book Dwonload Operation, bookID = \(bookID)"
    }
    
    override func execute() {
        guard let data: Data = Preference.resumeData[bookID] as Data?,
            let operation = DownloadBookOperation(bookID: bookID, resumeData: data) else {
                if let operation = DownloadBookOperation(bookID: bookID) {
                    produceOperation(operation)
                }
                
                finish()
                return
        }
        Network.shared.queue.addOperation(operation)
        finish()
    }
}
