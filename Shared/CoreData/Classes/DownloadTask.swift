//
//  DownloadTask.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import Foundation
import CoreData


class DownloadTask: NSManagedObject {
    
    class func fetchAddIfNotExist(bookID: String, context: NSManagedObjectContext) -> DownloadTask? {
        let fetchRequest = DownloadTask.fetchRequest() as! NSFetchRequest<DownloadTask>
        guard let book = Book.fetch(id: bookID, context: context) else {return nil}
        fetchRequest.predicate = NSPredicate(format: "book = %@", book)
        
        guard let downloadTask = try? context.fetch(fetchRequest).first ?? DownloadTask(context: context) else {return nil}
        downloadTask.creationTime = Date()
        downloadTask.book = book
        return downloadTask
    }
    
    class func fetchAll(_ context: NSManagedObjectContext) -> [DownloadTask] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DownloadTask")
        return fetch(fetchRequest, type: DownloadTask.self, context: context) ?? [DownloadTask]()
    }
    
    override func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)
        guard key == "totalBytesWritten" else {return}
        book?.willChangeValue(forKey: "downloadTask")
    }
    
    override func didChangeValue(forKey key: String) {
        super.didChangeValue(forKey: key)
        guard key == "totalBytesWritten" else {return}
        book?.didChangeValue(forKey: "downloadTask")
    }
    
    var state: DownloadTaskState {
        get {
            switch stateRaw {
            case 0: return .queued
            case 1: return .downloading
            case 2: return .paused
            default: return .error
            }
        }
        set {
            stateRaw = Int16(newValue.rawValue)
        }
    }
}

enum DownloadTaskState: Int {
    case queued, downloading, paused, error
}
