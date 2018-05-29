//
//  BookmarkMigrationOperation.swift
//  iOS
//
//  Created by Chris Li on 5/24/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import CoreData
import RealmSwift
import SwiftyUserDefaults

class BookmarkMigrationOperation: Operation {
    override func main() {
        migrateBookmarks()
        migrateVisibleLanguage()
    }
    
    private func migrateBookmarks() {
        let context = PersistentContainer.shared.newBackgroundContext()
        let request = Article.fetchRequest() as! NSFetchRequest<Article>
        request.predicate = NSPredicate(format: "isBookmarked == true")
        guard let articles = try? context.fetch(request), articles.count > 0 else {return}
        
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            for article in articles {
                guard let zimFileID = article.book?.id, let title = article.title,
                    let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else {continue}
                
                try database.write {
                    let bookmark = Bookmark()
                    bookmark.path = article.path
                    bookmark.zimFile = zimFile
                    bookmark.title = title
                    bookmark.snippet = article.snippet
                    bookmark.thumbImagePath = article.thumbImagePath
                    bookmark.date = article.bookmarkDate
                    
                    database.add(bookmark)
                }
            }
        } catch {}
    }
    
    private func migrateVisibleLanguage() {
        // do not migrate if language filter is already set
        guard Defaults[.libraryFilterLanguageCodes].count == 0 else {return}
        
        let context = PersistentContainer.shared.newBackgroundContext()
        let request = Language.fetchRequest() as! NSFetchRequest<Language>
        request.predicate = NSPredicate(format: "isDisplayed == true")
        guard let languages = try? context.fetch(request) else {return}
        
        let codes = languages.map({$0.code})
        Defaults[.libraryFilterLanguageCodes] = codes
    }
}
