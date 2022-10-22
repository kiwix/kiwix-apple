//
//  BookmarkOperations.swift
//  Kiwix
//
//  Created by Chris Li on 10/17/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import Foundation

struct BookmarkOperations {
    /// Create bookmark for an article
    /// - Parameter url: url of the article to bookmark
    static func create(_ url: URL?, withNotification: Bool = true) {
        guard let url = url else { return }
        let context = Database.shared.container.viewContext
        let bookmark = Bookmark(context: context)
        DispatchQueue.global().sync {
            bookmark.articleURL = url
            bookmark.created = Date()
            if let parser = try? HTMLParser(url: url) {
                bookmark.title = parser.title ?? ""
                bookmark.snippet = parser.getFirstSentence(languageCode: nil)?.string
                guard let zimFileID = url.host,
                      let zimFileID = UUID(uuidString: zimFileID),
                      let zimFile = try? context.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first else { return }
                bookmark.zimFile = zimFile
                if let imagePath = parser.getFirstImagePath() {
                    bookmark.thumbImageURL = URL(zimFileID: zimFileID.uuidString, contentPath: imagePath)
                }
            }
        }
        try? context.save()
        if withNotification {
            NotificationCenter.default.post(name: ReadingViewModel.bookmarkNotificationName, object: url)
        }
    }
    
    /// Delete an article bookmark
    /// - Parameter url: url of the article to delete bookmark
    static func delete(_ url: URL?, withNotification: Bool = true) {
        guard let url = url else { return }
        let context = Database.shared.container.viewContext
        let request = Bookmark.fetchRequest(predicate: NSPredicate(format: "articleURL == %@", url as CVarArg))
        guard let bookmark = try? context.fetch(request).first else { return }
        context.delete(bookmark)
        try? context.save()
        if withNotification {
            NotificationCenter.default.post(name: ReadingViewModel.bookmarkNotificationName, object: nil)
        }
    }
}
