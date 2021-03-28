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
    class func list() -> Results<Bookmark>? {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            return database.objects(Bookmark.self)
        } catch { return nil }
    }
    
    func get(url: URL) -> Bookmark? {
        guard let zimFileID = url.host else { return nil }
        return get(zimFileID: zimFileID, path: url.path)
    }
    
    func get(zimFileID: String, path: String) -> Bookmark? {
        let predicate = NSPredicate(format: "zimFile.fileID == %@ AND path == %@", zimFileID, path)
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            return database.objects(Bookmark.self).filter(predicate).first
        } catch { return nil }
    }
    
    func create(url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
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
                if let title = parser.getTitle(), title.count > 0 {
                    bookmark.title = title
                } else {
                    bookmark.title = zimFile.title
                }
                if #available(iOS 12.0, *, macOS 10.14) {
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
    }
    
    func delete(_ bookmark: Bookmark) {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            try database.write {
                database.delete(bookmark)
            }
        } catch {}
        updateBookmarkWidgetData()
    }
    
    private func updateBookmarkWidgetData() {
        DispatchQueue.global(qos: .background).async {
            guard let database = try? Realm(configuration: Realm.defaultConfig) else { return }
            let bookmarks = Array(database.objects(Bookmark.self).sorted(byKeyPath: "date", ascending: false).prefix(8))
            let data = bookmarks.compactMap { bookmark -> [String: Any]? in
                    guard let zimFile = bookmark.zimFile,
                        let url = URL(zimFileID: zimFile.fileID, contentPath: bookmark.path) else {return nil}
                    let thumbImageData: Data? = {
                        guard let thumbImagePath = bookmark.thumbImagePath else { return nil }
                        return ZimFileService.shared.getData(zimFileID: zimFile.fileID, contentPath: thumbImagePath)
                    }()
                    return [
                        "title": bookmark.title,
                        "url": url.absoluteString,
                        "thumbImageData": thumbImageData ?? bookmark.zimFile?.faviconData ?? Data()
                    ]
                }
            UserDefaults(suiteName: "group.kiwix")?.set(data, forKey: "bookmarks")
            #if !targetEnvironment(macCatalyst)
            NCWidgetController().setHasContent(data.count > 0, forWidgetWithBundleIdentifier: "self.Kiwix.Bookmarks")
            #endif
        }
    }
}
