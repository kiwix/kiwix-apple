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
import Combine

struct DownloadState: Codable {
    let downloaded: UInt
    let total: UInt
    let resumeData: Data?
    
    var isPaused: Bool {
        resumeData != nil
    }

    static func empty() -> DownloadState {
        .init(downloaded: 0, total: 1, resumeData: nil)
    }

    init(downloaded: UInt, total: UInt, resumeData: Data?) {
        guard total >= downloaded, total >= 0 else {
            self.downloaded = downloaded
            self.total = downloaded
            self.resumeData = resumeData
            return
        }
        self.downloaded = downloaded
        self.total = total
        self.resumeData = resumeData
    }

    func updatedWith(downloaded: UInt, total: UInt) -> DownloadState {
        DownloadState(downloaded: downloaded, total: total, resumeData: resumeData)
    }

    func updatedWith(resumeData: Data?) -> DownloadState {
        DownloadState(downloaded: downloaded, total: total, resumeData: resumeData)
    }
}
