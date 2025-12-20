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

final class ZimIntegrityModel: ObservableObject {
    
    enum CheckState: Equatable {
        case enqued
        case running
        case complete(isValid: Bool)
    }
    
    /// Integrity check info for a given ZIM file
    struct Info: Identifiable, Equatable {
        var id: UUID {
            zimFile.fileID
        }
        let checkID: UUID
        let zimFile: ZimFile
        let state: CheckState
    }
    
    @MainActor @Published var checks: [Info] = []
    /// Makes sure we ignore updates for a formerly cancelled check
    @MainActor
    private var checkID = UUID()

    @MainActor
    func reset() {
        checks.removeAll()
        checkID = UUID()
    }
    
    @MainActor
    private func addZimFiles(_ zimFiles: [ZimFile]) {
        checks = zimFiles.map({ zimFile in
            Info(checkID: checkID, zimFile: zimFile, state: .enqued)
        })
    }

    @MainActor
    private func updateProgress(zimFileID: UUID, state: CheckState) {
        checks = checks.map { info in
            if info.id == zimFileID, info.checkID == checkID {
                Info(checkID: info.checkID, zimFile: info.zimFile, state: state)
            } else {
                info
            }
        }
    }
    
    /// Check the integrity of given ZIM files
    func check(zimFiles: [ZimFile]) async {
        await addZimFiles(zimFiles)
        
        for zimFile in zimFiles {
            guard !Task.isCancelled else { return }
            zimFile.isIntegrityChecked = nil
            let fileID = zimFile.fileID
            let name = zimFile.name
            Log.LibraryOperations.notice("""
Started ZIM integrity check for \(fileID.uuidString, privacy: .public), \(name, privacy: .public)
""")
            await updateProgress(zimFileID: fileID, state: CheckState.running)
            let result = await ZimFileService.shared.checkIntegrity(zimFileID: fileID)
            Log.LibraryOperations.notice("""
Completed ZIM integrity check for \(fileID.uuidString, privacy: .public), \
\(name, privacy: .public), success: \(result, privacy: .public)
""")
            zimFile.isIntegrityChecked = result
            guard !Task.isCancelled else { return }
            await updateProgress(zimFileID: fileID, state: CheckState.complete(isValid: result))
        }
    }
}
