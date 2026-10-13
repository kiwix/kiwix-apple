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

import CoreData
import Defaults
import Foundation

/// Detects downloaded ZIM files that have a newer version listed in the catalog.
///
/// Two ZIM files are considered versions of the same content when they share
/// the same `titleID` (assigned by the catalog, see kiwix/libkiwix#1356) and the same `flavor`.
/// A ZIM file without a title ID never has an update. The result is persisted in `Defaults[.zimUpdatesAvailable]`, so it is
/// available immediately on launch and observable by SwiftUI views.
///
/// Detection only runs after the catalog refresh and on local library changes,
/// it never triggers a network request on its own.
enum ZimUpdates {

    /// Finds the newest catalog entry for each downloaded ZIM file.
    /// - Parameter context: the context to fetch from (must be called on the context's queue)
    /// - Returns: downloaded fileID -> newest not yet downloaded fileID
    static func findUpdates(in context: NSManagedObjectContext) -> [UUID: UUID] {
        let downloadedRequest = ZimFile.fetchRequest(predicate: ZimFile.Predicate.isDownloaded())
        guard let downloaded = try? context.fetch(downloadedRequest) else { return [:] }
        var updates: [UUID: UUID] = [:]
        for zimFile in downloaded {
            guard let titleID = zimFile.titleID, !titleID.isEmpty else { continue }
            let request = ZimFile.fetchRequest(
                predicate: newerVersionPredicate(for: zimFile, titleID: titleID),
                sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.created, ascending: false)]
            )
            request.fetchLimit = 1
            if let newest = try? context.fetch(request).first {
                updates[zimFile.fileID] = newest.fileID
            }
        }
        return updates
    }

    private static func newerVersionPredicate(for zimFile: ZimFile, titleID: String) -> NSPredicate {
        var predicates = [
            NSPredicate(format: "titleID == %@", titleID),
            NSPredicate(format: "created > %@", zimFile.created as CVarArg),
            NSPredicate(format: "downloadURL != nil"),
            ZimFile.Predicate.notDownloaded()
        ]
        if let flavor = zimFile.flavor, !flavor.isEmpty {
            predicates.append(NSPredicate(format: "flavor == %@", flavor))
        } else { // a missing flavor is stored as nil (catalog) or as an empty string (local file)
            predicates.append(NSPredicate(format: "flavor == nil OR flavor == ''"))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    /// Copies the catalog's title IDs onto downloaded ZIM files that are still listed in the catalog.
    ///
    /// The catalog sync does not touch downloaded records, and a ZIM file itself carries no title ID,
    /// so this is how a file downloaded before title IDs existed can learn its own. It only works while
    /// that exact release is still listed: the catalog lists current releases only, so a file that is
    /// already outdated stays without a title ID, and without an update, until a lookup by fileID exists.
    /// A catalog entry without a title ID never clears a stored one.
    /// - Parameters:
    ///   - catalog: the parsed catalog entries by fileID
    ///   - context: the context to update (must be called on the context's queue, saving is up to the caller)
    /// - Returns: the number of records that got a new title ID
    @discardableResult
    static func adoptTitleIDs(from catalog: [UUID: ZimFileMetaStruct], in context: NSManagedObjectContext) -> Int {
        // downloaded files are few, the catalog has thousands of entries: look each file up instead of filtering by ID
        let request = ZimFile.fetchRequest(predicate: ZimFile.Predicate.isDownloaded())
        guard let downloaded = try? context.fetch(request) else { return 0 }
        var adopted = 0
        for zimFile in downloaded {
            guard let titleID = catalog[zimFile.fileID]?.titleID,
                  !titleID.isEmpty,
                  zimFile.titleID != titleID else { continue }
            zimFile.titleID = titleID
            adopted += 1
        }
        return adopted
    }

    /// Recomputes the available updates and stores them in `Defaults`
    @MainActor
    static func refresh() async {
        let context = Database.shared.viewContext
        let updates = await context.perform { findUpdates(in: context) }
        store(updates)
    }

    /// Stores the given updates in `Defaults`, only writing when they changed
    @MainActor
    static func store(_ updates: [UUID: UUID]) {
        let stored = Dictionary(uniqueKeysWithValues: updates.map { ($0.key.uuidString, $0.value.uuidString) })
        if Defaults[.zimUpdatesAvailable] != stored {
            Defaults[.zimUpdatesAvailable] = stored
        }
    }

    /// The fileID of the newer version available for a downloaded ZIM file, if any
    static func availableUpdate(for fileID: UUID, in updates: [String: String]) -> UUID? {
        updates[fileID.uuidString].flatMap(UUID.init(uuidString:))
    }

    /// The fileIDs of all downloaded ZIM files that have an update available
    static func fileIDsWithUpdates(in updates: [String: String]) -> [UUID] {
        updates.keys.compactMap(UUID.init(uuidString:))
    }
}
