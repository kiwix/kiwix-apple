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
    
    func get(url: URL) -> Bookmark? {
        guard let zimFileID = url.host else { return nil }
        return get(zimFileID: zimFileID, path: url.path)
    }
    
    func get(zimFileID: String, path: String) -> Bookmark? {
        let predicate = NSPredicate(format: "zimFile.id == %@ AND path == %@", zimFileID, path)
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            return database.objects(Bookmark.self).filter(predicate).first
        } catch { return nil }
    }
    
    func create(url: URL) {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            guard let zimFileID = url.host,
                  let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID)
            else { return }
            
            let bookmark = Bookmark()
            bookmark.zimFile = zimFile
            bookmark.path = url.path
            bookmark.date = Date()
            
            let parser = try Parser(zimFileID: zimFileID, path: url.path)
            bookmark.title = parser.getTitle() ?? ""
            if #available(iOS 12.0, *) {
                bookmark.snippet = parser.getFirstSentence(languageCode: zimFile.languageCode)?.string
            } else {
                bookmark.snippet = parser.getFirstParagraph()?.string
            }
            if let imagePath = parser.getFirstImagePath(), let imageURL = URL(string: imagePath, relativeTo: url) {
                bookmark.thumbImagePath = imageURL.path
            }
            
            try database.write {
                database.add(bookmark)
            }
            self.updateBookmarkWidgetData()
        } catch {}
    }
    
    func delete(_ bookmark: Bookmark, completion: (() -> Void)? = nil) {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            try database.write {
                database.delete(bookmark)
            }
        } catch {}
        updateBookmarkWidgetData()
        completion?()
    }
    
    func updateBookmarkWidgetData() {
        guard #available(iOS 13, *) else {
            return
        }
        
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
        #if !targetEnvironment(macCatalyst)
        NCWidgetController().setHasContent(bookmarks.count > 0, forWidgetWithBundleIdentifier: "self.Kiwix.Bookmarks")
        #endif
    }
}
