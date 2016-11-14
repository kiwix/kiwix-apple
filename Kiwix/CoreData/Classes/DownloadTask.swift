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

    class func addOrUpdate(_ book: Book, context: NSManagedObjectContext) -> DownloadTask? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DownloadTask")
        fetchRequest.predicate = NSPredicate(format: "book = %@", book)
        let downloadTask = DownloadTask.fetch(fetchRequest, type: DownloadTask.self, context: context)?.first ?? insert(DownloadTask.self, context: context)
        
        downloadTask?.creationTime = Date()
        downloadTask?.book = book
        return downloadTask
    }
    
    class func fetchAll(_ context: NSManagedObjectContext) -> [DownloadTask] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DownloadTask")
        return fetch(fetchRequest, type: DownloadTask.self, context: context) ?? [DownloadTask]()
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
    
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumIntegerDigits = 3
        formatter.minimumFractionDigits = 2
        formatter.maximumIntegerDigits = 2
        return formatter
    }()

}

enum DownloadTaskState: Int {
    case queued, downloading, paused, error
}
