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

#if os(macOS)

import Defaults
import Foundation

struct DownloadLocationMac {
    let directory: URL?
    let isDefault: Bool
    let urlDescription: String
    
    static func load() -> Self {
        if let savedBookmark = MacDefaults.loadBookmark() {
            let urlState = savedBookmark.resolveBookmarkWithSecurityScope()
            switch urlState {
            case let .url(.some(url)):
                Log.DownloadService.debug("loaded downloads url: \(url.path(), privacy: .private)")
                return DownloadLocationMac(directory: url)
            case .url(.none):
                Log.DownloadService.warning("Unable to set the saved download url")
                return Self.default()
            case let .refreshed(newData, url):
                Log.DownloadService.debug("loaded downloads url with fresh bookmarks: \(url.path(), privacy: .private)")
                MacDefaults.saveBookmark(data: newData)
                return DownloadLocationMac(directory: url)
            }
        }
        return Self.default()
    }
    
    static func `default`() -> Self {
        DownloadLocationMac(directory: DownloadDestination.downloadLocalFolder())
    }
    
    init(directory: URL?) {
        self.directory = directory
        urlDescription = directory?.resolvingSymlinksInPath().path() ?? LocalString.download_mac_folder_unknown
        isDefault = DownloadDestination.isUsersDefaultDownloads(directory: directory)
    }
    
    nonisolated func volumeAndSpace() async -> String {
        let space: String? = if let space = directory?.availableSpace() {
            ByteCountFormatter.string(fromByteCount: space, countStyle: .file)
        } else {
            nil
        }
        let volume = directory?.volumeName()
        return [volume, space].compactMap { $0 }.joined(separator: "  ")
    }
    
    func save() -> Bool {
        if isDefault {
            // for some reasons the default downloads folder is not bookmarkable, using nil instead
            MacDefaults.saveBookmark(data: nil)
            return true
        }
        guard let directory,
              let bookmarkData = directory.bookmarkDataWithSecurityScope() else {
            return false
        }
        MacDefaults.saveBookmark(data: bookmarkData)
        Log.DownloadService.debug("saved url: \(directory.path(), privacy: .private)")
        return true
    }
}

enum MacDefaults {
    static func saveBookmark(data: Data?) {
        Defaults[.downloadsMacDirectoryBookmark] = data
    }
    static func loadBookmark() -> Data? {
        Defaults[.downloadsMacDirectoryBookmark]
    }
}
#endif
