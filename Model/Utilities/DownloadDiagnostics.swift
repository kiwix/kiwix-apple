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
