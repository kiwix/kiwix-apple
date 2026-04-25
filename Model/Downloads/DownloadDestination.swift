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
import Defaults
#endif

enum DownloadDestination {
    
    static func downloadLocalFolder() -> URL? {
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
    
    #if os(macOS)
    static func isUsersDefaultDownloads(directory: URL?) -> Bool {
        directory?.resolvingSymlinksInPath() == downloadLocalFolder()?.resolvingSymlinksInPath()
    }
    
    static func macUserDefinedDownloadDir() -> URL? {
        if let userDefinedBookmark = Defaults[.downloadsMacDirectoryBookmark] {
            switch userDefinedBookmark.resolveBookmarkWithSecurityScope() {
            case let .refreshed(newData, url):
                Defaults[.downloadsMacDirectoryBookmark] = newData
                return url
            case let .url(.some(url)):
                return url
            case .url(.none):
                return nil
            }
        } else {
            return Self.downloadLocalFolder()
        }
    }
    
    static func tempFilePathFor(zimFileID: UUID) -> URL? {
        let tempFileName = zimFileID.uuidString
        guard let dir = macUserDefinedDownloadDir() else {
            return nil
        }
        let access = dir.startAccessingSecurityScopedResource()
        if !access {
            Log.DownloadService.warning("accessing download folder is not possible")
        }
        return dir.appendingPathComponent(tempFileName, conformingTo: .zimFile)
    }
    
    #endif
    
    static func filePathFor(downloadURL: URL) -> URL? {
        downloadLocalFolder()?.appendingPathComponent(downloadURL.lastPathComponent)
    }
    
    static func filePathWithFallbacksFor(downloadURL: URL) -> URL? {
        #if os(iOS)
        guard let destination = filePathFor(downloadURL: downloadURL) else {
            return nil
        }
        #else
        guard let destination = macUserDefinedDownloadDir()?
            .appendingPathComponent(downloadURL.lastPathComponent) else {
            return nil
        }
        #endif
        
        var count = 0
        let maxAttempts = 3
        var nextDestination = destination
        while FileManager.default.fileExists(atPath: nextDestination.path()), count <= maxAttempts {
            nextDestination = DownloadDestination.alternateLocalPathFor(downloadURL: destination, count: count)
            count += 1
        }
        return nextDestination
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
}
