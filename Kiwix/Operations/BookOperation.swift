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
    
    override init(downloadTask: NSURLSessionDownloadTask) {
        progress = DownloadProgress(completedUnitCount: downloadTask.countOfBytesReceived, totalUnitCount: downloadTask.countOfBytesExpectedToReceive)
        bookID = downloadTask.taskDescription
        super.init(downloadTask: downloadTask)
        name = downloadTask.taskDescription
    }
    
    convenience init?(bookID: String) {
        let context = NSManagedObjectContext.mainQueueContext
        guard let book = Book.fetch(bookID, context: context),
            let url = book.url else { return nil }

        let task = Network.shared.session.downloadTaskWithURL(url)
        task.taskDescription = bookID
        self.init(downloadTask: task)
        
        let downloadTask = DownloadTask.addOrUpdate(book, context: context)
        downloadTask?.state = .Queued
        book.isLocal = nil
        
        progress.completedUnitCount = book.downloadTask?.totalBytesWritten ?? 0
        progress.totalUnitCount = book.fileSize
    }
    
    override func operationWillCancel(errors: [ErrorType]) {
        print("Download Task will cancel")
    }
    
    override func operationDidCancel() {
        print("Download Task did cancel")
        guard let bookID = bookID else {return}
        let context = NSManagedObjectContext.mainQueueContext
        context.performBlockAndWait {
            let book = Book.fetch(bookID, context: context)
            if !self.produceResumeData {book?.isLocal = false}
            
            guard let downloadTask = book?.downloadTask else {return}
            if self.produceResumeData {
                downloadTask.state = .Paused
            } else {
                context.deleteObject(downloadTask)
            }
            
        }
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
        context.performBlockAndWait {
            guard let zimFileURL = ZimMultiReader.shared.readers[self.bookID]?.fileURL else {return}
            _ = try? NSFileManager.defaultManager().removeItemAtURL(zimFileURL)
            
            // Core data is updated by scan book operation
            // Article removal is handled by cascade relationship
            
            guard let idxFolderURL = ZimMultiReader.shared.readers[self.bookID]?.idxFolderURL else {return}
            _ = try? NSFileManager.defaultManager().removeItemAtURL(idxFolderURL)
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
    }
    
    override func execute() {
        
    }
    
    private func correctFuckingResumeData(data: NSData?) -> NSData? {
        let kResumeCurrentRequest = "NSURLSessionResumeCurrentRequest"
        let kResumeOriginalRequest = "NSURLSessionResumeOriginalRequest"
        
        guard let data = data, let resumeDictionary = (try? NSPropertyListSerialization.propertyListWithData(data, options: [.MutableContainersAndLeaves], format: nil)) as? NSMutableDictionary else {
            return nil
        }
        
        resumeDictionary[kResumeCurrentRequest] = correctFuckingRequestData(resumeDictionary[kResumeCurrentRequest] as? NSData)
        resumeDictionary[kResumeOriginalRequest] = correctFuckingRequestData(resumeDictionary[kResumeOriginalRequest] as? NSData)
        
        let result = try? NSPropertyListSerialization.dataWithPropertyList(resumeDictionary, format: NSPropertyListFormat.XMLFormat_v1_0, options: NSPropertyListWriteOptions())
        return result
    }
    
    private func correctFuckingRequestData(data: NSData?) -> NSData? {
        guard let data = data else {
            return nil
        }
        if NSKeyedUnarchiver.unarchiveObjectWithData(data) != nil {
            return data
        }
        guard let archive = (try? NSPropertyListSerialization.propertyListWithData(data, options: [.MutableContainersAndLeaves], format: nil)) as? NSMutableDictionary else {
            return nil
        }
        // Rectify weird __nsurlrequest_proto_props objects to $number pattern
        var k = 0
        while archive["$objects"]?[1].objectForKey("$\(k)") != nil {
            k += 1
        }
        var i = 0
        while archive["$objects"]?[1].objectForKey("__nsurlrequest_proto_prop_obj_\(i)") != nil {
            let arr = archive["$objects"] as? NSMutableArray
            if let dic = arr?[1] as? NSMutableDictionary, let obj = dic["__nsurlrequest_proto_prop_obj_\(i)"] {
                dic.setObject(obj, forKey: "$\(i + k)")
                dic.removeObjectForKey("__nsurlrequest_proto_prop_obj_\(i)")
                arr?[1] = dic
                archive["$objects"] = arr
            }
            i += 1
        }
        if archive["$objects"]?[1]["__nsurlrequest_proto_props"] != nil {
            let arr = archive["$objects"] as? NSMutableArray
            if let dic = arr?[1] as? NSMutableDictionary, let obj = dic["__nsurlrequest_proto_props"] {
                dic.setObject(obj, forKey: "$\(i + k)")
                dic.removeObjectForKey("__nsurlrequest_proto_props")
                arr?[1] = dic
                archive["$objects"] = arr
            }
        }
        // Rectify weird "NSKeyedArchiveRootObjectKey" top key to NSKeyedArchiveRootObjectKey = "root"
        if archive["$top"]?["NSKeyedArchiveRootObjectKey"] != nil {
            archive["$top"]?.setObject(archive["$top"]?["NSKeyedArchiveRootObjectKey"], forKey: NSKeyedArchiveRootObjectKey)
            archive["$top"]?.removeObjectForKey("NSKeyedArchiveRootObjectKey")
        }
        // Re-encode archived object
        let result = try? NSPropertyListSerialization.dataWithPropertyList(archive, format: NSPropertyListFormat.BinaryFormat_v1_0, options: NSPropertyListWriteOptions())
        return result
    }
}
