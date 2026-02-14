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

struct FileExportData {
    let data: Data
    let fileName: String
    let fileExtension: String?

    init(data: Data, fileName: String, fileExtension: String? = "pdf") {
        self.data = data
        self.fileName = fileName
        self.fileExtension = fileExtension
    }
}

enum FileExporter {

    static func tempFileFrom(exportData: FileExportData) -> URL? {
        let extensionToAppend: String
        if let fileExtension = exportData.fileExtension {
            extensionToAppend = ".\(fileExtension)"
        } else {
            extensionToAppend = ""
        }
        let tempFileName = exportData.fileName.appending(extensionToAppend)
        let tempFileURL = URL(temporaryFileWithName: tempFileName)
        guard (try? exportData.data.write(to: tempFileURL)) != nil else {
            return nil
        }
        return tempFileURL
    }
}
