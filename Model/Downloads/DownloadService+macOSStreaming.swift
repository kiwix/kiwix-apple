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
private struct MacStreamingFilePreparation {
    let folder: URL
    let destination: URL
    let partialFileURL: URL
    let downloadedBytes: Int64
    let didAccessSecurityScopedResource: Bool
    let fileHandle: FileHandle
}

extension DownloadService {
    func restoreMacStreamingProgress() {
        for (zimFileID, metadata) in MacStreamingDownloadStore.all() {
            let downloaded = MacStreamingDownloadStore.partialFileSize(at: metadata.partialFileURL)
            progress.updateFor(
                uuid: zimFileID,
                downloaded: downloaded,
                total: max(metadata.expectedTotalBytes, downloaded)
            )
            progress.updateFor(uuid: zimFileID, withResumeData: metadata.resumeData(downloadedBytes: downloaded))
        }
    }

    func startMacStreamingDownload(
        zimFileID: UUID,
        downloadStruct: DownloadZimStruct,
        allowsCellularAccess: Bool,
        plan: DestinationPlan
    ) throws {
        var request = URLRequest(url: downloadStruct.url)
        request.allowsCellularAccess = allowsCellularAccess

        let metadata = MacStreamingDownloadMetadata(
            sourceURL: downloadStruct.url,
            allowsCellularAccess: allowsCellularAccess,
            destinationSnapshot: plan.snapshot,
            destinationPath: plan.destination.path(),
            partialFilePath: DownloadDestination.partialFilePathFor(destination: plan.destination).path(),
            expectedTotalBytes: downloadStruct.size,
            entityTag: nil,
            lastModified: nil
        )
        let task = try makeMacStreamingTask(
            request: request,
            zimFileID: zimFileID,
            metadata: metadata,
            preservePartialFile: false
        )
        progress.updateFor(uuid: zimFileID, downloaded: 0, total: downloadStruct.size)
        progress.updateFor(uuid: zimFileID, withResumeData: nil)
        task.resume()
    }

    func cancelMacStreamingDownload(zimFileID: UUID) async {
        let (dataTasks, _, _) = await directSession.tasks
        if let task = dataTasks.first(where: { $0.taskDescription == zimFileID.uuidString }) {
            sessionDelegate.cancelMacStreamingTask(taskID: task.taskIdentifier)
            task.cancel()
        }
        if let metadata = MacStreamingDownloadStore.metadata(for: zimFileID) {
            let folder = metadata.destinationSnapshot.resolvedFolderURL()
            try? DownloadDestination.removeFileIfExists(at: metadata.partialFileURL, in: folder)
        }
        await downloadManager.deleteDownloadTaskAsync(zimFileID: zimFileID)
    }

    func pauseMacStreamingDownload(zimFileID: UUID) {
        Task { @MainActor in
            let (dataTasks, _, _) = await directSession.tasks
            guard let task = dataTasks.first(where: { $0.taskDescription == zimFileID.uuidString }) else {
                return
            }
            sessionDelegate.cancelMacStreamingTask(taskID: task.taskIdentifier)
            task.cancel()
            progress.updateFor(uuid: zimFileID, withResumeData: MacStreamingDownloadStore.resumeData(for: zimFileID))
        }
    }

    func resumeMacStreamingDownload(zimFileID: UUID, resumeData: Data) async {
        guard let payload = try? JSONDecoder().decode(MacStreamingResumeData.self, from: resumeData) else {
            return
        }

        let metadata = resumeMetadata(from: payload)
        do {
            let task = try makeMacStreamingTask(
                request: resumeRequest(from: payload, downloadedBytes: metadata.downloadedBytes),
                zimFileID: zimFileID,
                metadata: metadata.metadata,
                preservePartialFile: true
            )
            progress.updateFor(
                uuid: zimFileID,
                downloaded: metadata.downloadedBytes,
                total: max(metadata.metadata.expectedTotalBytes, metadata.downloadedBytes)
            )
            task.resume()
        } catch {
            progress.updateFor(uuid: zimFileID, withResumeData: resumeData)
        }
    }

    private func makeMacStreamingTask(
        request: URLRequest,
        zimFileID: UUID,
        metadata: MacStreamingDownloadMetadata,
        preservePartialFile: Bool
    ) throws -> URLSessionDataTask {
        let preparedFile = try prepareMacStreamingFile(
            metadata: metadata,
            preservePartialFile: preservePartialFile
        )
        let updatedMetadata = updatedMetadata(from: metadata, using: preparedFile)

        let task = directSession.dataTask(with: request)
        task.taskDescription = zimFileID.uuidString
        task.countOfBytesClientExpectsToReceive = updatedMetadata.expectedTotalBytes

        let registration = MacStreamingTaskRegistration(
            taskID: task.taskIdentifier,
            zimFileID: zimFileID,
            metadata: updatedMetadata,
            folderURL: preparedFile.folder,
            didAccessSecurityScopedResource: preparedFile.didAccessSecurityScopedResource,
            destinationURL: preparedFile.destination,
            partialFileURL: preparedFile.partialFileURL,
            downloadedBytes: preparedFile.downloadedBytes,
            fileHandle: preparedFile.fileHandle
        )
        sessionDelegate.registerMacStreamingTask(registration)

        DownloadTaskDestinationStore.save(updatedMetadata.destinationSnapshot, for: zimFileID)
        MacStreamingDownloadStore.save(updatedMetadata, for: zimFileID)
        return task
    }

    private func prepareMacStreamingFile(
        metadata: MacStreamingDownloadMetadata,
        preservePartialFile: Bool
    ) throws -> MacStreamingFilePreparation {
        let folder = metadata.destinationSnapshot.resolvedFolderURL()
        let destination = folder.appendingPathComponent(metadata.destinationURL.lastPathComponent)
        let partialFileURL = DownloadDestination.partialFilePathFor(destination: destination)
        let downloadedBytes = preservePartialFile ? MacStreamingDownloadStore.partialFileSize(at: partialFileURL) : 0
        let didAccess = folder.startAccessingSecurityScopedResource()

        do {
            if !preservePartialFile {
                try DownloadDestination.removeFileIfExists(at: partialFileURL, in: folder)
                guard FileManager.default.createFile(atPath: partialFileURL.path(), contents: nil) else {
                    throw MacStreamingDownloadError.invalidPartialFilePath
                }
            }

            let fileHandle = try FileHandle(forWritingTo: partialFileURL)
            if preservePartialFile {
                try fileHandle.seekToEnd()
            } else {
                try fileHandle.truncate(atOffset: 0)
                try fileHandle.seek(toOffset: 0)
            }

            return MacStreamingFilePreparation(
                folder: folder,
                destination: destination,
                partialFileURL: partialFileURL,
                downloadedBytes: downloadedBytes,
                didAccessSecurityScopedResource: didAccess,
                fileHandle: fileHandle
            )
        } catch {
            if didAccess {
                folder.stopAccessingSecurityScopedResource()
            }
            throw error
        }
    }

    private func updatedMetadata(
        from metadata: MacStreamingDownloadMetadata,
        using preparedFile: MacStreamingFilePreparation
    ) -> MacStreamingDownloadMetadata {
        MacStreamingDownloadMetadata(
            sourceURL: metadata.sourceURL,
            allowsCellularAccess: metadata.allowsCellularAccess,
            destinationSnapshot: metadata.destinationSnapshot,
            destinationPath: preparedFile.destination.path(),
            partialFilePath: preparedFile.partialFileURL.path(),
            expectedTotalBytes: max(metadata.expectedTotalBytes, preparedFile.downloadedBytes),
            entityTag: metadata.entityTag,
            lastModified: metadata.lastModified
        )
    }

    private func resumeMetadata(
        from payload: MacStreamingResumeData
    ) -> (metadata: MacStreamingDownloadMetadata, downloadedBytes: Int64) {
        let folder = payload.destinationSnapshot.resolvedFolderURL()
        let destination = folder.appendingPathComponent(payload.destinationURL.lastPathComponent)
        let partialFileURL = DownloadDestination.partialFilePathFor(destination: destination)
        let downloadedBytes = MacStreamingDownloadStore.partialFileSize(at: partialFileURL)

        let metadata = MacStreamingDownloadMetadata(
            sourceURL: payload.sourceURL,
            allowsCellularAccess: payload.allowsCellularAccess,
            destinationSnapshot: payload.destinationSnapshot,
            destinationPath: destination.path(),
            partialFilePath: partialFileURL.path(),
            expectedTotalBytes: max(payload.expectedTotalBytes, downloadedBytes),
            entityTag: payload.entityTag,
            lastModified: payload.lastModified
        )
        return (metadata, downloadedBytes)
    }

    private func resumeRequest(from payload: MacStreamingResumeData, downloadedBytes: Int64) -> URLRequest {
        var request = URLRequest(url: payload.sourceURL)
        request.allowsCellularAccess = payload.allowsCellularAccess
        if downloadedBytes > 0 {
            request.setValue("bytes=\(downloadedBytes)-", forHTTPHeaderField: "Range")
            if let entityTag = payload.entityTag {
                request.setValue(entityTag, forHTTPHeaderField: "If-Range")
            } else if let lastModified = payload.lastModified {
                request.setValue(lastModified, forHTTPHeaderField: "If-Range")
            }
        }
        return request
    }
}
#endif
