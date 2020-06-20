//
//  BookmarkService.swift
//  Kiwix
//
//  Created by Chris Li on 1/1/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Foundation
import NotificationCenter
import RealmSwift

class BookmarkService {
    private let database = try? Realm(configuration: Realm.defaultConfig)
    
    func updateBookmarkWidgetData() {
        let bookmarks: [Bookmark] = {
            var bookmarks = [Bookmark]()
            if let result = database?.objects(Bookmark.self).sorted(byKeyPath: "date", ascending: false) {
                for bookmark in result {
                    guard bookmarks.count < 8 else {break}
                    bookmarks.append(bookmark)
                }
            }
            return bookmarks
        }()
        let bookmarksData = bookmarks.compactMap { (bookmark) -> [String: Any]? in
            guard let zimFile = bookmark.zimFile,
                let url = URL(zimFileID: zimFile.id, contentPath: bookmark.path) else {return nil}
            return [
                "title": bookmark.title,
                "url": url.absoluteString,
                "thumbImageData": bookmark.thumbImageData ?? bookmark.zimFile?.faviconData ?? Data()
            ]
        }
        UserDefaults(suiteName: "group.kiwix")?.set(bookmarksData, forKey: "bookmarks")
        NCWidgetController().setHasContent(bookmarks.count > 0, forWidgetWithBundleIdentifier: "self.Kiwix.Bookmarks")
    }
}
