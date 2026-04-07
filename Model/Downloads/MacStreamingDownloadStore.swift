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
struct MacStreamingResumeData: Codable, Equatable {
    let sourceURL: URL
    let allowsCellularAccess: Bool
    let destinationSnapshot: DownloadTaskDestinationSnapshot
    let destinationPath: String
    let partialFilePath: String
    let downloadedBytes: Int64
    let expectedTotalBytes: Int64
    let entityTag: String?
    let lastModified: String?

    var destinationURL: URL {
        URL(fileURLWithPath: destinationPath)
    }

    var partialFileURL: URL {
        URL(fileURLWithPath: partialFilePath)
    }
}

struct MacStreamingDownloadMetadata: Codable, Equatable {
    let sourceURL: URL
    let allowsCellularAccess: Bool
    let destinationSnapshot: DownloadTaskDestinationSnapshot
    let destinationPath: String
    let partialFilePath: String
    let expectedTotalBytes: Int64
    let entityTag: String?
    let lastModified: String?

    var destinationURL: URL {
        URL(fileURLWithPath: destinationPath)
    }

    var partialFileURL: URL {
        URL(fileURLWithPath: partialFilePath)
    }

    func resumeData(downloadedBytes: Int64? = nil) -> Data? {
        let bytes = max(downloadedBytes ?? MacStreamingDownloadStore.partialFileSize(at: partialFileURL), 0)
        let payload = MacStreamingResumeData(
            sourceURL: sourceURL,
            allowsCellularAccess: allowsCellularAccess,
            destinationSnapshot: destinationSnapshot,
            destinationPath: destinationPath,
            partialFilePath: partialFilePath,
            downloadedBytes: bytes,
            expectedTotalBytes: max(expectedTotalBytes, bytes),
            entityTag: entityTag,
            lastModified: lastModified
        )
        return try? JSONEncoder().encode(payload)
    }
}

enum MacStreamingDownloadStore {
    private static let key = "macStreamingDownloads"

    static func metadata(for uuid: UUID, userDefaults: UserDefaults = .standard) -> MacStreamingDownloadMetadata? {
        read(userDefaults: userDefaults)[uuid.uuidString]
    }

    static func save(_ metadata: MacStreamingDownloadMetadata, for uuid: UUID, userDefaults: UserDefaults = .standard) {
        var downloads = read(userDefaults: userDefaults)
        downloads[uuid.uuidString] = metadata
        write(downloads, userDefaults: userDefaults)
    }

    static func remove(for uuid: UUID, userDefaults: UserDefaults = .standard) {
        var downloads = read(userDefaults: userDefaults)
        downloads.removeValue(forKey: uuid.uuidString)
        write(downloads, userDefaults: userDefaults)
    }

    static func all(userDefaults: UserDefaults = .standard) -> [UUID: MacStreamingDownloadMetadata] {
        read(userDefaults: userDefaults).reduce(into: [:]) { result, entry in
            guard let uuid = UUID(uuidString: entry.key) else { return }
            result[uuid] = entry.value
        }
    }

    static func resumeData(for uuid: UUID, userDefaults: UserDefaults = .standard) -> Data? {
        metadata(for: uuid, userDefaults: userDefaults)?.resumeData()
    }

    static func partialFileSize(at url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    private static func read(userDefaults: UserDefaults) -> [String: MacStreamingDownloadMetadata] {
        guard let data = userDefaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: MacStreamingDownloadMetadata].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func write(_ downloads: [String: MacStreamingDownloadMetadata], userDefaults: UserDefaults) {
        if downloads.isEmpty {
            userDefaults.removeObject(forKey: key)
            return
        }
        if let encoded = try? JSONEncoder().encode(downloads) {
            userDefaults.set(encoded, forKey: key)
        }
    }
}

enum MacStreamingDownloadError: LocalizedError {
    case invalidPartialFilePath
    case invalidHTTPStatus(Int)
    case unableToResume
}

struct MacStreamingDownloadProgress {
    let zimFileID: UUID
    let downloadedBytes: Int64
    let totalBytes: Int64
}

struct MacStreamingPreparedResponse {
    let zimFileID: UUID
    let response: HTTPURLResponse
    let downloadedBytes: Int64
    let totalBytes: Int64
}

struct MacStreamingTaskRegistration {
    let taskID: Int
    let zimFileID: UUID
    let metadata: MacStreamingDownloadMetadata
    let folderURL: URL
    let didAccessSecurityScopedResource: Bool
    let destinationURL: URL
    let partialFileURL: URL
    let downloadedBytes: Int64
    let fileHandle: FileHandle
}

private final class MacStreamingDownloadContext {
    let zimFileID: UUID
    let sourceURL: URL
    let allowsCellularAccess: Bool
    let folderURL: URL
    let didAccessSecurityScopedResource: Bool
    let destinationSnapshot: DownloadTaskDestinationSnapshot
    let destinationURL: URL
    let partialFileURL: URL
    var expectedTotalBytes: Int64
    var downloadedBytes: Int64
    let fileHandle: FileHandle

    init(registration: MacStreamingTaskRegistration) {
        let metadata = registration.metadata
        zimFileID = registration.zimFileID
        sourceURL = metadata.sourceURL
        allowsCellularAccess = metadata.allowsCellularAccess
        folderURL = registration.folderURL
        didAccessSecurityScopedResource = registration.didAccessSecurityScopedResource
        destinationSnapshot = metadata.destinationSnapshot
        destinationURL = registration.destinationURL
        partialFileURL = registration.partialFileURL
        expectedTotalBytes = metadata.expectedTotalBytes
        downloadedBytes = registration.downloadedBytes
        fileHandle = registration.fileHandle
    }

    var metadata: MacStreamingDownloadMetadata {
        MacStreamingDownloadMetadata(
            sourceURL: sourceURL,
            allowsCellularAccess: allowsCellularAccess,
            destinationSnapshot: destinationSnapshot,
            destinationPath: destinationURL.path(),
            partialFilePath: partialFileURL.path(),
            expectedTotalBytes: expectedTotalBytes,
            entityTag: nil,
            lastModified: nil
        )
    }
}

final class MacStreamingDownloadRegistry {
    private let queue = DispatchQueue(label: "downloads.mac.streaming.registry")
    private var contexts = [Int: MacStreamingDownloadContext]()

    func register(_ registration: MacStreamingTaskRegistration) {
        let context = MacStreamingDownloadContext(registration: registration)
        queue.sync {
            contexts[registration.taskID] = context
        }
    }

    func prepareResponse(taskID: Int, response: HTTPURLResponse) throws -> MacStreamingPreparedResponse? {
        try queue.sync {
            guard let context = contexts[taskID] else {
                return nil
            }
            guard (200..<300).contains(response.statusCode) else {
                throw MacStreamingDownloadError.invalidHTTPStatus(response.statusCode)
            }
            if context.downloadedBytes > 0 {
                guard response.statusCode == 206 || response.statusCode == 200 else {
                    throw MacStreamingDownloadError.unableToResume
                }
                if response.statusCode == 200 {
                    try context.fileHandle.truncate(atOffset: 0)
                    try context.fileHandle.seek(toOffset: 0)
                    context.downloadedBytes = 0
                }
            }
            let remainingBytes = max(response.expectedContentLength, 0)
            let totalBytes = max(context.downloadedBytes + remainingBytes, context.expectedTotalBytes)
            context.expectedTotalBytes = totalBytes
            MacStreamingDownloadStore.save(context.metadata, for: context.zimFileID)
            return MacStreamingPreparedResponse(
                zimFileID: context.zimFileID,
                response: response,
                downloadedBytes: context.downloadedBytes,
                totalBytes: totalBytes
            )
        }
    }

    func append(data: Data, taskID: Int) throws -> MacStreamingDownloadProgress? {
        try queue.sync {
            guard let context = contexts[taskID] else {
                return nil
            }
            try context.fileHandle.write(contentsOf: data)
            context.downloadedBytes += Int64(data.count)
            let totalBytes = max(context.expectedTotalBytes, context.downloadedBytes)
            context.expectedTotalBytes = totalBytes
            return MacStreamingDownloadProgress(
                zimFileID: context.zimFileID,
                downloadedBytes: context.downloadedBytes,
                totalBytes: totalBytes
            )
        }
    }

    func finish(taskID: Int) -> MacStreamingDownloadMetadata? {
        queue.sync {
            guard let context = contexts.removeValue(forKey: taskID) else {
                return nil
            }
            try? context.fileHandle.close()
            if context.didAccessSecurityScopedResource {
                context.folderURL.stopAccessingSecurityScopedResource()
            }
            return context.metadata
        }
    }

    func cancel(taskID: Int) {
        queue.sync {
            guard let context = contexts.removeValue(forKey: taskID) else {
                return
            }
            try? context.fileHandle.close()
            if context.didAccessSecurityScopedResource {
                context.folderURL.stopAccessingSecurityScopedResource()
            }
        }
    }
}
#endif
