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

/// Async reading data in chunks via LibZim
/// to be used with ``DataStream``
struct ZimContentProvider: DataProvider {
    
    typealias Element = URLContent
    private let url: URL

    init(for url: URL) {
        self.url = url
    }

    func data(from start: UInt, to end: UInt) async -> URLContent? {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .utility) {
                let content = ZimFileService.shared.getURLContent(url: url, start: start, end: end)
                continuation.resume(returning: content)
            }
        }
    }
}

/// Async reading data in chunks directly from the file system
/// to be used with ``DataStream``
struct ZimDirectContentProvider: DataProvider {

    typealias Element = URLContent
    private let directAccess: DirectAccessInfo
    private let contentSize: UInt

    init(directAccess: DirectAccessInfo, contentSize: UInt) {
        self.directAccess = directAccess
        self.contentSize = contentSize
    }

    func data(from start: UInt, to end: UInt) async -> URLContent? {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .utility) {
                let handle = FileHandle(forReadingAtPath: directAccess.path)
                try? handle?.seek(toOffset: UInt64(directAccess.offset + start))
                let dataLength = Int(min(contentSize - start, end - start + 1))
                let data = handle?.readData(ofLength: dataLength)
                try? handle?.close()
                let urlContent: URLContent?
                if let data {
                    urlContent = URLContent(data: data, start: start, end: end)
                } else {
                    urlContent = nil
                }
                continuation.resume(returning: urlContent)
            }
        }
    }
}
