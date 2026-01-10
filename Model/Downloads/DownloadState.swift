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

@MainActor
struct DownloadUIState {
    enum State {
        case resumed
        case paused(isOnline: Bool)
    }
    
    let percent: String?
    let size: String
    let state: State
    let hasResumeData: Bool
    let progress: Progress
    
    static func empty() -> DownloadUIState {
        DownloadUIState(
            percent: nil,
            size: "",
            state: .resumed,
            hasResumeData: false,
            progress: progressFor(downloaded: 0, total: 1)
        )
    }
    
    private init(
        percent: String?,
        size: String,
        state: State,
        hasResumeData: Bool,
        progress: Progress
    ) {
        self.percent = percent
        self.size = size
        self.state = state
        self.hasResumeData = hasResumeData
        self.progress = progress
    }
    
    init(downloadState: DownloadState, isOnline: Bool) {
        debugPrint("downloadState: \(downloadState), isOnline: \(isOnline)")
        size = Formatter.size.string(fromByteCount: downloadState.downloaded)
        switch (downloadState.isPaused, isOnline) {
        case (false, true):
            state = .resumed
        case (true, _):
            state = .paused(isOnline: isOnline)
        case (_, false):
            state = .paused(isOnline: false)
        }
        hasResumeData = downloadState.resumeData != nil
        let progress = Self.progressFor(downloaded: downloadState.downloaded, total: downloadState.total)
        percent = Formatter.percent.string(from: NSNumber(value: progress.fractionCompleted))
        self.progress = progress
    }
    
    private static func progressFor(downloaded: Int64, total: Int64) -> Progress {
        let prog = Progress(totalUnitCount: total)
        prog.completedUnitCount = downloaded
        prog.kind = .file
        prog.fileTotalCount = 1
        prog.fileOperationKind = .downloading
        return prog
    }
}

struct DownloadState: Codable {
    let downloaded: Int64
    let total: Int64
    let isPaused: Bool
    let resumeData: Data?

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
