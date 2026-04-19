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
import Defaults

@globalActor actor IOActor {
    static let shared = IOActor()
}

#if os(macOS)
struct DirectDownloadInfo: Sendable {
    /// Initial before starting the download
    let offset: UInt
    let file: URL
    
    init?(initialOffset: UInt, zimFileID: UUID) {
        guard let fileURL = DownloadDestination.tempFilePathFor(zimFileID: zimFileID) else {
            Log.IO.error("there's no file path for: \(zimFileID.uuidString)")
            return nil
        }
        offset = initialOffset
        file = fileURL
    }
}

enum AppendStatus: Sendable {
    case appended
    case full
}

final actor DirectFileWriter {
    static let cacheLimit: Int = 1_048_576 // 1MB * 5 // 5 MB
    
    let file: URL
    private var cachedData = Data()
    
    init?(directAccess: DirectDownloadInfo) {
        file = directAccess.file
        _ = file.startAccessingSecurityScopedResource()
        defer { file.stopAccessingSecurityScopedResource() }
        if !FileManager.default.isWritableFile(atPath: file.path()) {
            guard FileManager.default.createFile(atPath: file.path, contents: nil, ) else {
                Log.IO.error("cannot create file @ \(self.file.path())")
                return nil
            }
        }
    }
    
    func append(data: Data) -> AppendStatus {
        cachedData.append(data)
        if cachedData.count < Self.cacheLimit {
            return .appended
        } else {
            return .full
        }
    }
    
    func writeToDisk() -> Bool {
        do {
            try write(data: cachedData)
            Log.IO.info("writing: \(self.sizeOf(self.cachedData))")
            cachedData = Data()
            return true
        } catch {
            Log.IO.error("cannot append data to \(self.file.path()): \(error.localizedDescription)")
            return false
        }
    }
    
    func fileSize() -> UInt? {
        _ = file.startAccessingSecurityScopedResource()
        defer { file.stopAccessingSecurityScopedResource() }
        guard let attribs = try? FileManager.default.attributesOfItem(atPath: file.path()),
              let size = attribs[FileAttributeKey.size] as? NSNumber else {
            return nil
        }
        return size.uintValue
    }
    
    private func write(data: Data) throws {
        _ = file.startAccessingSecurityScopedResource()
        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
        try handle.close()
        file.stopAccessingSecurityScopedResource()
    }
    
    private func sizeOf(_ data: Data) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(data.bytes.byteCount), countStyle: .file)
    }
}
#endif
