//
//  URL.swift
//  Kiwix
//
//  Created by Chris Li on 11/6/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//
import Foundation

extension URL {
    init?(zimFileID: String, contentPath: String) {
        let baseURLString = "kiwix://" + zimFileID
        guard let encoded = contentPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {return nil}
        self.init(string: encoded, relativeTo: URL(string: baseURLString))
    }

    var isKiwixURL: Bool {
        return scheme?.caseInsensitiveCompare("kiwix") == .orderedSame
    }

    var isExternal: Bool {
        ["http", "https"].contains(scheme)
    }

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
}
