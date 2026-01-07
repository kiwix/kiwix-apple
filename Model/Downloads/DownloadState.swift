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
    let downloaded: Int64
    let total: Int64
    let isPaused: Bool
    let resumeData: Data?

    static func empty() -> DownloadState {
        .init(downloaded: 0, total: 1, resumeData: nil, isPaused: false)
    }

    init(downloaded: Int64, total: Int64, resumeData: Data?, isPaused: Bool) {
        guard total >= downloaded, total >= 0 else {
            self.downloaded = downloaded
            self.total = downloaded
            self.resumeData = resumeData
            self.isPaused = isPaused
            return
        }
        self.downloaded = downloaded
        self.total = total
        self.resumeData = resumeData
        self.isPaused = isPaused
    }

    func updatedWith(downloaded: Int64, total: Int64) -> DownloadState {
        DownloadState(downloaded: downloaded, total: total, resumeData: resumeData, isPaused: false)
    }

    func updatedWith(resumeData: Data?, isPaused: Bool) -> DownloadState {
        DownloadState(downloaded: downloaded, total: total, resumeData: resumeData, isPaused: isPaused)
    }
}
