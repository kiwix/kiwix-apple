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

extension Migrations {
    
    static func tags(using context: NSManagedObjectContext) -> Migration {
        Migration(userDefaultsKey: "migrate_downloaded_zim_tags") {
            let request = ZimFile.fetchRequest(predicate: ZimFile.Predicate.isDownloaded())
            let zimFiles: [ZimFile] = (try? context.fetch(request)) ?? []
            let zimFileData: [UUID: Data] = zimFiles.reduce(into: [:]) { partialResult, zimFile in
                partialResult[zimFile.fileID] = zimFile.fileURLBookmark
            }
            Task {
                for item in zimFileData {
                    let fileId: UUID = item.key
                    let fileIdString = fileId.uuidString
                    let bookmark: Data = item.value
                    do {
                        try await ZimFileService.shared.revalidate(fileURLBookmark: bookmark, for: fileId)
                        if let fileURL = await ZimFileService.shared.getFileURL(zimFileID: fileId) {
                            await LibraryOperations.open(url: fileURL)
                            let fileName = fileURL.lastPathComponent
                            Log.LibraryOperations.debug("tags migrated for: \(fileName, privacy: .public)")
                        } else {
                            Log.LibraryOperations.warning("no fileURL for: \(fileIdString, privacy: .public)")
                        }
                    } catch {
                        Log.LibraryOperations.warning("invalid fileBookmark for: \(fileIdString, privacy: .public)")
                    }
                }
            }
            return true
        }
    }
}
