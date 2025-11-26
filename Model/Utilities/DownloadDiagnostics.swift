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
import Foundation

enum DownloadDiagnostics {
    
    // swiftlint:disable:next force_unwrap
    private static let fakeURL = URL(string: "https://kiwix.org/diag.zim")!
    
    static func path() {
        guard let path = DownloadDestination.filePathFor(
            downloadURL: Self.fakeURL,
            taskId: "diag"
        ) else {
            return
        }
        Log.DownloadService.notice("Download path: \(path, privacy: .public)")
    }
}

#endif
