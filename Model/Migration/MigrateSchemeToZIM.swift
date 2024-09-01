// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import Foundation
import CoreData

enum Migrations {

    /// Change the bookmarks articleURLs from "kiwix://..." to "zim://..."
    /// - Parameter context: DataBase context
    /// - Returns: Migration - general struct
    static func schemeToZIM(using context: NSManagedObjectContext) -> Migration {
        Migration(userDefaultsKey: "migrate_scheme_to_zim") {
            // bookmarks:
            let bookmarkPredicate = NSPredicate(format: "articleURL BEGINSWITH[cd] %@", "kiwix://")
            let bookmarkRequest = Bookmark.fetchRequest(predicate: bookmarkPredicate)
            let bookmarks: [Bookmark] = (try? context.fetch(bookmarkRequest)) ?? []
            for bookmark in bookmarks {
                bookmark.articleURL = bookmark.articleURL.updatedToZIMSheme()
            }
            if context.hasChanges {
                try? context.save()
            }
            return true
        }
    }
}
