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

#if os(macOS)
extension DownloadSessionDelegate {
    func registerMacStreamingTask(_ registration: MacStreamingTaskRegistration) {
        macStreamingRegistry.register(registration)
    }

    func cancelMacStreamingTask(taskID: Int) {
        macStreamingRegistry.cancel(taskID: taskID)
    }

    nonisolated func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        guard let taskDescription = dataTask.taskDescription,
              let zimFileID = UUID(uuidString: taskDescription),
              let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            DownloadUI.showAlert(.downloadErrorGeneric(
                description: LocalString.download_service_error_option_invalid_response
            ))
            return
        }

        do {
            if let prepared = try macStreamingRegistry.prepareResponse(
                taskID: dataTask.taskIdentifier,
                response: httpResponse
            ) {
                Task { @MainActor [progress] in
                    progress.updateFor(
                        uuid: prepared.zimFileID,
                        downloaded: prepared.downloadedBytes,
                        total: prepared.totalBytes
                    )
                }
            }
            completionHandler(.allow)
        } catch {
            macStreamingRegistry.cancel(taskID: dataTask.taskIdentifier)
            cleanupMacStreamingPartialFile(for: zimFileID)
            downloadManager.deleteDownloadTask(zimFileID: zimFileID)
            DownloadUI.showAlert(.downloadErrorZIM(
                zimFileID: zimFileID,
                errorMessage: errorMessage(for: error)
            ))
            completionHandler(.cancel)
        }
    }

    nonisolated func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        do {
            guard let streamingProgress = try macStreamingRegistry.append(
                data: data,
                taskID: dataTask.taskIdentifier
            ) else {
                return
            }
            Task { @MainActor [progress] in
                progress.updateFor(
                    uuid: streamingProgress.zimFileID,
                    downloaded: streamingProgress.downloadedBytes,
                    total: streamingProgress.totalBytes
                )
            }
        } catch {
            guard let taskDescription = dataTask.taskDescription,
                  let zimFileID = UUID(uuidString: taskDescription) else {
                return
            }
            macStreamingRegistry.cancel(taskID: dataTask.taskIdentifier)
            cleanupMacStreamingPartialFile(for: zimFileID)
            downloadManager.deleteDownloadTask(zimFileID: zimFileID)
            DownloadUI.showAlert(.downloadErrorZIM(
                zimFileID: zimFileID,
                errorMessage: errorMessage(for: error)
            ))
            dataTask.cancel()
        }
    }

    nonisolated func handleMacStreamingCompletion(
        dataTask: URLSessionDataTask,
        zimFileID: UUID,
        error: NSError?
    ) {
        if let error {
            guard error.code != NSURLErrorCancelled else {
                return
            }
            macStreamingRegistry.cancel(taskID: dataTask.taskIdentifier)
            cleanupMacStreamingPartialFile(for: zimFileID)
            let errorDesc = DownloadErrors.localizedString(from: error)
            downloadManager.deleteDownloadTask(zimFileID: zimFileID)
            DownloadUI.showAlert(.downloadErrorZIM(zimFileID: zimFileID, errorMessage: errorDesc))
            return
        }

        guard let metadata = macStreamingRegistry.finish(taskID: dataTask.taskIdentifier) else {
            return
        }

        let folder = metadata.destinationSnapshot.resolvedFolderURL()
        let partialFileURL = folder.appendingPathComponent(metadata.partialFileURL.lastPathComponent)
        var destination = folder.appendingPathComponent(metadata.destinationURL.lastPathComponent)

        do {
            try DownloadDestination.withFolderAccess(to: folder) {
                var count = 0
                let maxAttempts = 3
                var nextDestination = destination
                while FileManager.default.fileExists(atPath: nextDestination.path()), count <= maxAttempts {
                    nextDestination = DownloadDestination.alternateLocalPathFor(downloadURL: destination, count: count)
                    count += 1
                }
                destination = nextDestination
                try FileManager.default.moveItem(at: partialFileURL, to: destination)
            }
        } catch {
            cleanupMacStreamingPartialFile(for: zimFileID)
            let errorMessage = LocalString.download_service_error_option_unable_to_move_file
            DownloadUI.showAlert(.downloadErrorZIM(zimFileID: zimFileID, errorMessage: errorMessage))
            downloadManager.deleteDownloadTask(zimFileID: zimFileID)
            return
        }

        Task {
            await LibraryOperations.open(url: destination)
            await scheduleDownloadCompleteNotification(zimFileID: zimFileID)
            downloadManager.deleteDownloadTask(zimFileID: zimFileID)
        }
    }

    nonisolated func cleanupMacStreamingPartialFile(for zimFileID: UUID) {
        guard let metadata = MacStreamingDownloadStore.metadata(for: zimFileID) else {
            return
        }
        let folder = metadata.destinationSnapshot.resolvedFolderURL()
        let partialFileURL = folder.appendingPathComponent(metadata.partialFileURL.lastPathComponent)
        try? DownloadDestination.removeFileIfExists(at: partialFileURL, in: folder)
    }

    nonisolated func errorMessage(for error: Error) -> String {
        if let error = error as? MacStreamingDownloadError,
           case .invalidHTTPStatus(let statusCode) = error {
            return LocalString.download_service_error_option_http_status(withArgs: "\(statusCode)")
        }
        return LocalString.download_service_error_option_directory
    }
}
#endif
