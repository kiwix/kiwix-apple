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

#endif
