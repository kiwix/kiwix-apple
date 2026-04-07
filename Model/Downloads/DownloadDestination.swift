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

enum DownloadDestination {
    
    static func downloadLocalFolder(selectedFolder: URL? = nil) -> URL? {
        if let selectedFolder {
            return selectedFolder
        }
        // determine which directory should the file be moved to
        #if os(macOS)
        let searchPath = FileManager.SearchPathDirectory.downloadsDirectory
        #elseif os(iOS)
        let searchPath = FileManager.SearchPathDirectory.documentDirectory
        #endif

        // move file
        guard let directory = FileManager.default.urls(for: searchPath, in: .userDomainMask).first else {
            Log.DownloadService.fault(
                "Cannot find download directory!"
            )
            return nil
        }
        return directory
    }
    
    static func filePathFor(downloadURL: URL, in folder: URL? = nil) -> URL? {
        downloadLocalFolder(selectedFolder: folder)?.appendingPathComponent(downloadURL.lastPathComponent)
    }

    static func partialFilePathFor(destination: URL) -> URL {
        destination.appendingPathExtension("downloading")
    }
    
    static func alternateLocalPathFor(downloadURL url: URL, count: Int) -> URL {
        guard count > 0 else {
            return url
        }
        let fileName = url.deletingPathExtension().lastPathComponent
        let newFileName = fileName.appending("-\(count + 1)")
        return url
            .deletingLastPathComponent()
            .appendingPathComponent(newFileName, conformingTo: .zimFile)
    }

    static func availableCapacity(in folder: URL) -> Int64? {
        try? withFolderAccess(to: folder) {
            try folder
                .resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                .volumeAvailableCapacityForImportantUsage
        }
    }

    static func fileExists(at url: URL, in folder: URL) -> Bool {
        withFolderAccess(to: folder) {
            FileManager.default.fileExists(atPath: url.path())
        }
    }

    static func removeFileIfExists(at url: URL, in folder: URL) throws {
        try withFolderAccess(to: folder) {
            guard FileManager.default.fileExists(atPath: url.path()) else {
                return
            }
            try FileManager.default.removeItem(at: url)
        }
    }

    static func withFolderAccess<Result>(to folder: URL, _ body: () throws -> Result) rethrows -> Result {
        #if os(macOS)
        let didAccess = folder.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                folder.stopAccessingSecurityScopedResource()
            }
        }
        #endif
        return try body()
    }

    #if os(macOS)
    static func folderBookmarkData(for folder: URL) -> Data? {
        _ = folder.startAccessingSecurityScopedResource()
        defer { folder.stopAccessingSecurityScopedResource() }
        return try? folder.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    static func resolveFolderBookmarkData(_ data: Data) -> (url: URL, updatedBookmarkData: Data?)? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }
        let updatedBookmarkData = isStale ? folderBookmarkData(for: url) : nil
        return (url, updatedBookmarkData)
    }
    #endif
}
