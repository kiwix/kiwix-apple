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

enum URLSchemeType {
    case kiwix
    case geo
    case external

    init(scheme: String?) {
        guard let scheme else {
            self = .external
            return
        }
        if scheme.caseInsensitiveCompare("kiwix") == .orderedSame {
            self = .kiwix
            return
        }
        if scheme.caseInsensitiveCompare("geo") == .orderedSame {
            self = .geo
            return
        }
        self = .external
    }
}

extension URL {
    init?(zimFileID: String, contentPath: String) {
        let baseURLString = "kiwix://" + zimFileID
        guard let encoded = contentPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {return nil}
        self.init(string: encoded, relativeTo: URL(string: baseURLString))
    }

    var schemeType: URLSchemeType {
        URLSchemeType(scheme: scheme)
    }

    var isExternal: Bool { schemeType == .external }
    var isKiwixURL: Bool { schemeType == .kiwix }
    var isGeoURL: Bool { schemeType == .geo }

    // swiftlint:disable:next force_try
    static let documentDirectory = try! FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
    )

    init(appStoreReviewForName appName: String, appStoreID: String) {
        self.init(string: "itms-apps://itunes.apple.com/us/app/\(appName)/\(appStoreID)?action=write-review")!
    }

    init(temporaryFileWithName fileName: String) {
        let directory = FileManager.default.temporaryDirectory
        if #available(macOS 13.0, iOS 16.0, *) {
            self = directory.appending(path: fileName)
        } else {
            self = directory.appendingPathComponent(fileName)
        }
    }

    func toTemporaryFileURL() -> URL? {
        URL(temporaryFileWithName: lastPathComponent)
    }
}
