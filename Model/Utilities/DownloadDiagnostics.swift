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
import SystemPackage
#endif

enum DownloadDiagnostics {
    
    static func path() {
        guard let url = DownloadDestination.downloadLocalFolder() else {
            return
        }
        let tempDir = ProcessInfo().environment["TMPDIR"] ?? "unknown"
        logPath(prefix: "Temp", path: tempDir)
        logPath(prefix: "Download", path: url.path())
    }
    
    static func testWritingAFile() {
        let testURL = URL(string: "https://kiwix.org/diag.test")!
        guard let destinationURL = DownloadDestination.filePathFor(downloadURL: testURL) else {
            return
        }
        if let tempDir = ProcessInfo().environment["TMPDIR"],
           let tempDirURL = URL(string: tempDir) {
            let tempFileURL = tempDirURL.appendingPathComponent(testURL.lastPathComponent)
            if FileManager.default.fileExists(atPath: destinationURL.path()) {
                try? FileManager.default.removeItem(at: destinationURL)
            }
            
            if FileManager.default.createFile(atPath: tempFileURL.path(), contents: Data("test".utf8)) {
                do {
                    try FileManager.default.moveItem(atPath: tempFileURL.path(), toPath: destinationURL.path())
                    Log.DownloadService.notice("successfully moved test file to downloads folder")
                    try FileManager.default.removeItem(at: destinationURL)
                    Log.DownloadService.notice("successfully removed test file in downloads folder")
                } catch {
                    Log.DownloadService.error("""
        moving temp file failed: \(error.localizedDescription, privacy: .public)
        """)
                }
            } else {
                Log.DownloadService.error("cannot write to temp directory")
            }
        } else {
            Log.DownloadService.error("cannot access temp directory")
        }
    }
    
    private static func logPath(prefix: String, path: String) {
        let isWritable = FileManager.default.isWritableFile(atPath: path)
        Log.DownloadService.notice("""
\(prefix, privacy: .public) path: \(path, privacy: .public) isWritable: \(isWritable, privacy: .public)
""")
#if os(macOS)
        let filePath = FilePath(path)
        if let stat = try? filePath.stat() {
            let permissions = stat.mode.permissions.debugDescription
            let userID = stat.userID.rawValue.description
            let groupID = stat.groupID.rawValue.description
            Log.DownloadService.notice("""
            \(prefix, privacy: .public) path: \(path, privacy: .public) \
            permissions: \(permissions, privacy: .public) \
            userID: \(userID, privacy: .public) \
            groupID: \(groupID, privacy: .public)
            """)
        }
#endif
    }
}
