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
import UserNotifications

/// Extracted common functions from iOS and macOS DownloadDelegates
enum DownloadCommonDelegate {
    
    // swiftlint:disable function_body_length
    /// This is called upon both successful and unsuccessful completion !
    /// "The only errors your delegate receives through the error parameter are client-side errors,
    /// such as being unable to resolve the hostname or connect to the host.
    /// To check for server-side errors, inspect the response property
    /// of the task parameter received by this callback."
    /// - Parameters:
    ///   - downloadManager: passed in from the (iOS/macOS) DownloadDelegate
    ///   - progress: passed in from the (iOS/macOS) DownloadDelegate
    ///   - session: the current session
    ///   - task: if the task is cancelled / paused by the user it will be called because of that
    ///   - error: client-side errors, including task cancelled / paused
    static func handleCompleteWithError(
        downloadManager: DownloadTaskManager,
        progress: DownloadTasksPublisher,
        session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        guard let zimFileID = task.zimFileID else {
            Log.DownloadService.fault("Cannot convert taskDescription: \(task.taskDescription ?? "", privacy: .public)")
            return
        }
        
        // download finished without client side errors
        // inspect the response property
        // eg: the status code should be in the 200 < 300 range
        guard let error = error as NSError? else {
            guard let httpResponse = task.response as? HTTPURLResponse else {
                Log.DownloadService.fault("response is not an HTTPURLResponse")
                downloadManager.deleteDownloadTask(zimFileID: zimFileID)
                let errorMessage = LocalString.download_service_error_option_invalid_response
                DownloadUI.showAlert(.downloadErrorZIM(zimFileID: zimFileID,
                                                       errorMessage: errorMessage))
                return
            }
            let fileId = zimFileID.uuidString
            if (200..<300).contains(httpResponse.statusCode) {
                Log.DownloadService.info(
                    "Download Ok, zimId: \(fileId, privacy: .public)"
                )
            } else {
                let statusCode = httpResponse.statusCode
                Log.DownloadService.error("""
                Download error: \(fileId, privacy: .public). \
                URL: \(httpResponse.url?.absoluteString ?? "unknown", privacy: .public). \
                Status code: \(statusCode, privacy: .public),
                Error: \(httpResponse.debugDescription, privacy: .public)
                """)
                downloadManager.deleteDownloadTask(zimFileID: zimFileID)
            }
            return
        }
        
        // at this point we do know there was a client side error:
        
        // check if the task was cancelled / paused
        guard error.code != NSURLErrorCancelled else {
            // the resume data was already saved above with:
            // task.cancel { [progress] resumeData in
            return
        }
        
        // Save the error description and resume data if there are new result data
        let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
        Task { @MainActor [progress] in
            progress.updateFor(uuid: zimFileID, withResumeData: resumeData)
            
            await Database.shared.viewContext.perform {
                let request = DownloadTask.fetchRequest(fileID: zimFileID)
                request.fetchLimit = 1
                guard let downloadTask = try? request.execute().first else { return }
                downloadTask.error = error.localizedDescription
                let context = Database.shared.viewContext
                try? context.save()
            }
        }
        let fileId = zimFileID.uuidString
        let errorDebugDesc = error.debugDescription
        Log.DownloadService.error(
            "Finished for zimId: \(fileId, privacy: .public). with: \(errorDebugDesc, privacy: .public)")
        
        let errorDesc = DownloadErrors.localizedString(from: error)
        downloadManager.deleteDownloadTask(zimFileID: zimFileID)
        DownloadUI.showAlert(.downloadErrorZIM(zimFileID: zimFileID,
                                               errorMessage: errorDesc))
    }
    // swiftlint:enable function_body_length
    
    
    // MARK: - Notification
    
    static func scheduleDownloadCompleteNotification(zimFileID: UUID) async {
        let center = UserNotifications.UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus != .denied else { return }
         
        let zimFileName: String? = await Database.shared.viewContext.perform {
            let request = ZimFile.fetchRequest(fileID: zimFileID)
            request.fetchLimit = 1
            if let zimFile = try? request.execute().first {
                return zimFile.name
            } else {
                return nil
            }
        }
        
        // configure notification content
        let content = UNMutableNotificationContent()
        content.title = LocalString.download_service_complete_title
        content.sound = .default
        if let zimFileName {
            content.body = LocalString.download_service_complete_description(withArgs: zimFileName)
        }
        // schedule notification
        let request = UNNotificationRequest(identifier: zimFileID.uuidString,
                                            content: content,
                                            trigger: nil)
        try? await center.add(request)
    }
}
