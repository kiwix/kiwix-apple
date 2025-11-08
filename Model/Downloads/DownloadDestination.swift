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
    
    static func filePathFor(downloadURL: URL, taskId: String) -> URL? {
        // determine which directory should the file be moved to
        #if os(macOS)
        let searchPath = FileManager.SearchPathDirectory.downloadsDirectory
        #elseif os(iOS)
        let searchPath = FileManager.SearchPathDirectory.documentDirectory
        #endif

        // move file
        guard let directory = FileManager.default.urls(for: searchPath, in: .userDomainMask).first else {
            Log.DownloadService.fault(
                "Cannot find download directory! downloadTask: \(taskId, privacy: .public)"
            )
            return nil
        }
        return directory.appendingPathComponent(downloadURL.lastPathComponent)
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
