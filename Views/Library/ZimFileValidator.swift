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

@MainActor
enum ZimFileIntegrity {
    
    /// Check the integrity of given ZIM files
    /// - Parameter files: [zimFile.fileID: zimFile.name]
    static func check(zimFiles: [ZimFile], using context: NSManagedObjectContext) async {
        for zimFile in zimFiles {
            let fileID = zimFile.fileID
            let name = zimFile.name
            Log.LibraryOperations.notice("""
Started ZIM integrity check for \(fileID.uuidString, privacy: .public), \(name, privacy: .public)
""")
            NotificationCenter.startIntegrityCheckZIM(title: name)
            let result = await ZimFileService.shared.checkIntegrity(zimFileID: fileID)
            Log.LibraryOperations.notice("""
Completed ZIM integrity check for \(fileID.uuidString, privacy: .public), \
\(name, privacy: .public), success: \(result, privacy: .public)
""")
            zimFile.isIntegrityChecked = result
            if context.hasChanges {
                try? context.save()
            }
        }
        NotificationCenter.stopIntegrityCheckZIM()
    }
}
