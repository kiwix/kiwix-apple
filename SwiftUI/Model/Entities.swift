//
//  Entities.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import CoreData

class Bookmark: NSManagedObject, Identifiable {
    var id: URL { articleURL }
    
    @NSManaged var articleURL: URL
    @NSManaged var thumbImageURL: URL?
    @NSManaged var title: String
    @NSManaged var snippet: String?
    @NSManaged var created: Date
    
    class func fetchRequest() -> NSFetchRequest<Bookmark> {
        super.fetchRequest() as! NSFetchRequest<Bookmark>
    }
}

class DownloadTask: NSManagedObject, Identifiable {
    var id: UUID { fileID }

    @NSManaged var created: Date
    @NSManaged var downloadedBytes: Int64
    @NSManaged var fileID: UUID
    @NSManaged var resumeData: Data?
    @NSManaged var totalBytes: Int64
    
    @NSManaged var zimFile: ZimFile?
    
    class func fetchRequest(predicate: NSPredicate? = nil) -> NSFetchRequest<DownloadTask> {
        let request = super.fetchRequest() as! NSFetchRequest<DownloadTask>
        request.predicate = predicate
        return request
    }
}

class ZimFile: NSManagedObject, Identifiable {
    var id: UUID { fileID }
    
    @NSManaged var articleCount: Int64
    @NSManaged var category: String
    @NSManaged var created: Date
    @NSManaged var downloadURL: URL?
    @NSManaged var faviconData: Data?
    @NSManaged var faviconURL: URL?
    @NSManaged var fileDescription: String
    @NSManaged var fileID: UUID
    @NSManaged var fileURLBookmark: Data?
    @NSManaged var flavor: String?
    @NSManaged var hasDetails: Bool
    @NSManaged var hasPictures: Bool
    @NSManaged var hasVideos: Bool
    @NSManaged var includedInSearch: Bool
    @NSManaged var languageCode: String
    @NSManaged var mediaCount: Int64
    @NSManaged var name: String
    @NSManaged var persistentID: String
    @NSManaged var size: Int64
    
    @NSManaged var downloadTask: DownloadTask?
    
    class func fetchRequest(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor] = []
    ) -> NSFetchRequest<ZimFile> {
        let request = super.fetchRequest() as! NSFetchRequest<ZimFile>
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
    
    class func fetchRequest(fileID: UUID) -> NSFetchRequest<ZimFile> {
        let request = super.fetchRequest() as! NSFetchRequest<ZimFile>
        request.predicate = NSPredicate(format: "fileID == %@", fileID as CVarArg)
        return request
    }
}
