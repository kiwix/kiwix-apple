//
//  BookmarksMigration.swift
//  Kiwix

import Foundation
import CoreData

private extension ZimFile {
    var groupById: String {
        [name, flavor, languageCode].compactMap { $0 }.joined(separator: ":")
    }
}

enum BookmarksMigration {

    static func migrationForCustomApps() async {
        guard FeatureFlags.hasLibrary == false else { return }
        await Database.shared.container.performBackgroundTask { context in
            let sortDescriptors = [NSSortDescriptor(keyPath: \ZimFile.created, ascending: true)]
            guard var zimFiles = try? ZimFile.fetchRequest(predicate: ZimFile.Predicate.isDownloaded,
                                                           sortDescriptors: sortDescriptors).execute(),
                  zimFiles.count > 1,
                  let latest = zimFiles.popLast() else {
                return
            }
            for zimFile in zimFiles {
                migrateFrom(zimFile: zimFile, toZimFile: latest, using: context)
            }
        }
    }

    /// Migrates the bookmars from an old to new zim file,
    /// also updates the bookmark urls accordingly (based on the new zim id as the host of those URLs)
    private static func migrateFrom(
        zimFile fromZim: ZimFile,
        toZimFile toZim: ZimFile,
        using context: NSManagedObjectContext
    ) {
        guard fromZim.bookmarks.isEmpty == false else { return }
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let newHost = toZim.fileID.uuidString
        fromZim.bookmarks.forEach { (bookmark: Bookmark) in
            bookmark.zimFile = toZim
            if let newArticleURL = bookmark.articleURL.updateHost(to: newHost) {
                bookmark.articleURL = newArticleURL
            }
            bookmark.thumbImageURL = bookmark.thumbImageURL?.updateHost(to: newHost)
        }
        if context.hasChanges { try? context.save() }
    }
}

extension URL {
    func updateHost(to newHost: String) -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }
        components.host = newHost
        return components.url
    }
}
