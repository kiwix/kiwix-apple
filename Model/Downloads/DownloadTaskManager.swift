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
    
    func deleteDownloadTaskAsync(zimFileID: UUID) async {
        progress.resetFor(uuid: zimFileID)
        await Database.shared.viewContext.perform {
            do {
                let request = DownloadTask.fetchRequest(fileID: zimFileID)
                guard let downloadTask = try request.execute().first else { return }
                let context = Database.shared.viewContext
                context.delete(downloadTask)
                try context.save()
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
