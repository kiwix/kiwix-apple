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
    static let Environment = Logger(subsystem: subsystem, category: "Environment")
    static let DownloadService = Logger(subsystem: subsystem, category: "DownloadService")
    static let FaviconDownloadService = Logger(subsystem: subsystem, category: "FaviconDownloadService")
    static let LibraryOperations = Logger(subsystem: subsystem, category: "LibraryOperations")
    static let QRCode = Logger(subsystem: subsystem, category: "QRCode")
    static let OPDS = Logger(subsystem: subsystem, category: "OPDS")
    static let URLSchemeHandler = Logger(subsystem: subsystem, category: "URLSchemeHandler")
    static let Branding = Logger(subsystem: subsystem, category: "Branding")
    static let Payment = Logger(subsystem: subsystem, category: "Payment")
}
