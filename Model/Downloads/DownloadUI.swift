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

enum DownloadUI {
    static func showAlert(_ alert: ActiveAlert) {
        Task { @MainActor in
            NotificationCenter.default.post(name: .alert,
                                            object: nil,
                                            userInfo: ["alert": alert])
        }
    }
    
    static func showQuestion(_ question: ActiveQuestion) {
        Task { @MainActor in
            NotificationCenter.default.post(name: .question, object: nil, userInfo: ["question": question])
        }
    }
}
