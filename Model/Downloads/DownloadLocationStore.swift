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
import AppKit
import Defaults
#endif

struct DownloadTaskDestinationSnapshot: Codable, Equatable {
    let folderPath: String
    let folderBookmark: Data?

    init(folder: URL, folderBookmark: Data? = nil) {
        self.folderPath = folder.standardizedFileURL.path()
        #if os(macOS)
        self.folderBookmark = folderBookmark ?? DownloadDestination.folderBookmarkData(for: folder)
        #else
        self.folderBookmark = nil
        #endif
    }

    var folderURL: URL {
        URL(fileURLWithPath: folderPath, isDirectory: true)
    }

    #if os(macOS)
    func resolvedFolderURL() -> URL {
        if let folderBookmark,
           let resolved = DownloadDestination.resolveFolderBookmarkData(folderBookmark)?.url {
            return resolved
        }
        return folderURL
    }
    #endif
}

enum DownloadTaskDestinationStore {
    private static let key = "downloadTaskDestinations"

    static func destination(
        for uuid: UUID,
        userDefaults: UserDefaults = .standard
    ) -> DownloadTaskDestinationSnapshot? {
        read(userDefaults: userDefaults)[uuid.uuidString]
    }

    static func save(
        _ snapshot: DownloadTaskDestinationSnapshot,
        for uuid: UUID,
        userDefaults: UserDefaults = .standard
    ) {
        var destinations = read(userDefaults: userDefaults)
        destinations[uuid.uuidString] = snapshot
        write(destinations, userDefaults: userDefaults)
    }

    static func remove(for uuid: UUID, userDefaults: UserDefaults = .standard) {
        var destinations = read(userDefaults: userDefaults)
        destinations.removeValue(forKey: uuid.uuidString)
        write(destinations, userDefaults: userDefaults)
    }

    private static func read(userDefaults: UserDefaults) -> [String: DownloadTaskDestinationSnapshot] {
        guard let data = userDefaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: DownloadTaskDestinationSnapshot].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func write(_ destinations: [String: DownloadTaskDestinationSnapshot], userDefaults: UserDefaults) {
        if destinations.isEmpty {
            userDefaults.removeObject(forKey: key)
            return
        }
        if let encoded = try? JSONEncoder().encode(destinations) {
            userDefaults.set(encoded, forKey: key)
        }
    }
}

#if os(macOS)
struct SavedDownloadLocationResolution {
    enum State: Equatable {
        case missing
        case invalid
        case valid(URL)
    }

    let state: State
    let displayPath: String
}

enum DownloadLocationSettings {
    static func save(folder: URL) {
        Defaults[.downloadDirectoryPath] = folder.standardizedFileURL.path()
        Defaults[.downloadDirectoryBookmark] = DownloadDestination.folderBookmarkData(for: folder)
    }

    static func resolution() -> SavedDownloadLocationResolution {
        let defaultPath = DownloadDestination.downloadLocalFolder()?.standardizedFileURL.path() ?? ""
        let storedPath = Defaults[.downloadDirectoryPath] ?? defaultPath

        guard let bookmark = Defaults[.downloadDirectoryBookmark] else {
            if storedPath.isEmpty || storedPath == defaultPath {
                return SavedDownloadLocationResolution(state: .missing, displayPath: defaultPath)
            }
            return SavedDownloadLocationResolution(state: .invalid, displayPath: storedPath)
        }

        guard let resolved = DownloadDestination.resolveFolderBookmarkData(bookmark) else {
            return SavedDownloadLocationResolution(state: .invalid, displayPath: storedPath)
        }

        let resolvedPath = resolved.url.standardizedFileURL.path()
        if let updatedBookmarkData = resolved.updatedBookmarkData {
            Defaults[.downloadDirectoryBookmark] = updatedBookmarkData
        }
        Defaults[.downloadDirectoryPath] = resolvedPath
        return SavedDownloadLocationResolution(state: .valid(resolved.url), displayPath: resolvedPath)
    }
}

@MainActor
struct MacDownloadLocationSelector {
    typealias ChooseFolder = @MainActor (_ initialFolder: URL, _ message: String?) async -> URL?

    var alwaysAsk: () -> Bool = { Defaults[.downloadAlwaysAsk] }
    var savedLocation: () -> SavedDownloadLocationResolution = { DownloadLocationSettings.resolution() }
    var defaultDownloadsFolder: () -> URL? = { DownloadDestination.downloadLocalFolder() }
    var saveFolder: (URL) -> Void = { DownloadLocationSettings.save(folder: $0) }
    var chooseFolder: ChooseFolder = { initialFolder, message in
        await DownloadFolderPanel.chooseFolder(initialFolder: initialFolder, message: message)
    }

    func selectFolder(message: String?) async -> URL? {
        guard let defaultDownloadsFolder = defaultDownloadsFolder() else {
            return nil
        }

        let resolution = savedLocation()
        let initialFolder: URL

        switch resolution.state {
        case .valid(let url):
            if !alwaysAsk() {
                return url
            }
            initialFolder = url
        case .missing:
            if !alwaysAsk() {
                return defaultDownloadsFolder
            }
            initialFolder = defaultDownloadsFolder
        case .invalid:
            initialFolder = defaultDownloadsFolder
        }

        guard let selectedFolder = await chooseFolder(initialFolder, message) else {
            return nil
        }
        saveFolder(selectedFolder)
        return selectedFolder
    }
}

enum DownloadFolderPanel {
    @MainActor
    static func chooseFolder(initialFolder: URL, message: String?) async -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.directoryURL = initialFolder
        panel.message = message ?? ""
        panel.prompt = LocalString.common_button_choose
        panel.title = LocalString.download_settings_choose_title

        return await withCheckedContinuation { continuation in
            panel.begin { response in
                continuation.resume(returning: response == .OK ? panel.url : nil)
            }
        }
    }
}

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

    init(
        zimFileID: UUID,
        sourceURL: URL,
        allowsCellularAccess: Bool,
        folderURL: URL,
        didAccessSecurityScopedResource: Bool,
        destinationSnapshot: DownloadTaskDestinationSnapshot,
        destinationURL: URL,
        partialFileURL: URL,
        expectedTotalBytes: Int64,
        downloadedBytes: Int64,
        fileHandle: FileHandle
    ) {
        self.zimFileID = zimFileID
        self.sourceURL = sourceURL
        self.allowsCellularAccess = allowsCellularAccess
        self.folderURL = folderURL
        self.didAccessSecurityScopedResource = didAccessSecurityScopedResource
        self.destinationSnapshot = destinationSnapshot
        self.destinationURL = destinationURL
        self.partialFileURL = partialFileURL
        self.expectedTotalBytes = expectedTotalBytes
        self.downloadedBytes = downloadedBytes
        self.fileHandle = fileHandle
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

    func register(
        taskID: Int,
        zimFileID: UUID,
        sourceURL: URL,
        allowsCellularAccess: Bool,
        folderURL: URL,
        didAccessSecurityScopedResource: Bool,
        destinationSnapshot: DownloadTaskDestinationSnapshot,
        destinationURL: URL,
        partialFileURL: URL,
        expectedTotalBytes: Int64,
        downloadedBytes: Int64,
        fileHandle: FileHandle
    ) {
        let context = MacStreamingDownloadContext(
            zimFileID: zimFileID,
            sourceURL: sourceURL,
            allowsCellularAccess: allowsCellularAccess,
            folderURL: folderURL,
            didAccessSecurityScopedResource: didAccessSecurityScopedResource,
            destinationSnapshot: destinationSnapshot,
            destinationURL: destinationURL,
            partialFileURL: partialFileURL,
            expectedTotalBytes: expectedTotalBytes,
            downloadedBytes: downloadedBytes,
            fileHandle: fileHandle
        )
        queue.sync {
            contexts[taskID] = context
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
