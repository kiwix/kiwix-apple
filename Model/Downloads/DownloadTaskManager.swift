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
import Foundation

@MainActor
struct DownloadTaskManager {
    
    private let progress: DownloadTasksPublisher
    
    init(progress: DownloadTasksPublisher) {
        self.progress = progress
    }
    
    nonisolated func deleteDownloadTask(zimFileID: UUID) {
        Task { @MainActor in
            await deleteDownloadTaskAsync(zimFileID: zimFileID)
        }
    }
    
    private func deleteDownloadTaskAsync(zimFileID: UUID) async {
        // What we really want is to update the ZimFile entry
        // to indicate that it has no more ZimFile.downloadTask associated with it
        // The UI relies on this fact in it's display hierarchy.
        // Deleting the DownloadTask directly poorly propagates upwards to the ZimFile.
        // So instead let's set ZimFile.downloadTask = nil, which instantly updates the UI,
        // and then we can do the deletion of the DownloadTask itself
        let downloadTaskObjectId: NSManagedObjectID? = await Database.shared.viewContext.perform {
            do {
                let context = Database.shared.viewContext
                let zimRequest = ZimFile.fetchRequest(fileID: zimFileID)
                zimRequest.fetchLimit = 1
                let zimFile: ZimFile? = try context.fetch(zimRequest).first
                let downloadTaskObjectId = zimFile?.downloadTask?.objectID
                zimFile?.downloadTask = nil
                try context.save()
                return downloadTaskObjectId
            } catch {
                let errorDesc = "\(zimFileID.uuidString), \(error.localizedDescription)"
                Log.DownloadService.error(
                    "Could not set ZimFile's downloadTask to nil for: \(errorDesc, privacy: .public)"
                )
                return nil
            }
        }
       
        if let downloadTaskObjectId {
            // Update the UI now
            progress.resetFor(uuid: zimFileID)
            
            // Clean up the now orphaned DownloadTask
            let context = Database.shared.viewContext
            await context.perform {
                do {
                    try context.execute(NSBatchDeleteRequest(objectIDs: [downloadTaskObjectId]))
                } catch {
                    let fileId = zimFileID.uuidString
                    let errorDesc = error.localizedDescription
                    Log.DownloadService.error(
                        "Error deleting download task for: \(fileId, privacy: .public), \(errorDesc, privacy: .public)"
                    )
                }
            }
        }
    }
}
