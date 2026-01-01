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

struct DownloadHeadCheck {
    
    func check(task: URLSessionDownloadTask) async -> Bool {
        guard let request = task.originalRequest else {
            return false
        }
        var headRequest = request
        headRequest.httpMethod = "HEAD"
        guard let (_, response) = try? await URLSession.shared.data(for: headRequest) else {
            return false
        }
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
              ((200..<300)).contains(statusCode) else {
            return false
        }
        
        return true
    }
}
