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

import os

private let subsystem = "org.kiwix.kiwix"

struct Log {
    static let Browser = OSLog(subsystem: subsystem, category: "Browser")
    static let DownloadService = OSLog(subsystem: subsystem, category: "DownloadService")
    static let FaviconDownloadService = OSLog(subsystem: subsystem, category: "FaviconDownloadService")
    static let LibraryService = OSLog(subsystem: subsystem, category: "LibraryService")
    static let LibraryOperations = OSLog(subsystem: subsystem, category: "LibraryOperations")
    static let OPDS = OSLog(subsystem: subsystem, category: "OPDS")
    static let URLSchemeHandler = OSLog(subsystem: subsystem, category: "URLSchemeHandler")
    static let Branding = OSLog(subsystem: subsystem, category: "Branding")
}
