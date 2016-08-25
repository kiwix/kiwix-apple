//
//  DownloadTask.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import Foundation
import CoreData


class DownloadTask: NSManagedObject {

    class func addOrUpdate(book: Book, context: NSManagedObjectContext) -> DownloadTask? {
        let fetchRequest = NSFetchRequest(entityName: "DownloadTask")
        fetchRequest.predicate = NSPredicate(format: "book = %@", book)
        let downloadTask = DownloadTask.fetch(fetchRequest, type: DownloadTask.self, context: context)?.first ?? insert(DownloadTask.self, context: context)
        
        downloadTask?.creationTime = NSDate()
        downloadTask?.book = book
        return downloadTask
    }
    
    class func fetchAll(context: NSManagedObjectContext) -> [DownloadTask] {
        let fetchRequest = NSFetchRequest(entityName: "DownloadTask")
        return fetch(fetchRequest, type: DownloadTask.self, context: context) ?? [DownloadTask]()
    }
    
    var state: DownloadTaskState {
        get {
            switch stateRaw {
            case 0: return .Queued
            case 1: return .Downloading
            case 2: return .Paused
            default: return .Error
            }
        }
        set {
            stateRaw = Int16(newValue.rawValue)
        }
    }

}

enum DownloadTaskState: Int {
    case Queued, Downloading, Paused, Error
}
