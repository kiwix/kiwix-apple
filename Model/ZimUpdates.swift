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
/// the same `persistentID` (the ZIM `Name` metadata) and the same `flavor`.
/// The result is persisted in `Defaults[.zimUpdatesAvailable]`, so it is
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
        for zimFile in downloaded where !zimFile.persistentID.isEmpty {
            let request = ZimFile.fetchRequest(
                predicate: newerVersionPredicate(for: zimFile),
                sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.created, ascending: false)]
            )
            request.fetchLimit = 1
            if let newest = try? context.fetch(request).first {
                updates[zimFile.fileID] = newest.fileID
            }
        }
        return updates
    }

    private static func newerVersionPredicate(for zimFile: ZimFile) -> NSPredicate {
        var predicates = [
            NSPredicate(format: "persistentID == %@", zimFile.persistentID),
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
