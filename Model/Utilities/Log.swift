//  Copyright © 2023 Kiwix.

import os

private let subsystem = "org.kiwix.kiwix"

struct Log {
    static let DownloadService = OSLog(subsystem: subsystem, category: "DownloadService")
    static let FaviconDownloadService = OSLog(subsystem: subsystem, category: "FaviconDownloadService")
    static let LibraryService = OSLog(subsystem: subsystem, category: "LibraryService")
    static let LibraryOperations = OSLog(subsystem: subsystem, category: "LibraryOperations")
    static let OPDS = OSLog(subsystem: subsystem, category: "OPDS")
    static let URLSchemeHandler = OSLog(subsystem: subsystem, category: "URLSchemeHandler")
    static let Branding = OSLog(subsystem: subsystem, category: "Branding")
}
