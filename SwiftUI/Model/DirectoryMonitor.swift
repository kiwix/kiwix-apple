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

actor DirectoryMonitor {
    private let url: URL
    private let onChange: (@Sendable (URL) -> Void)?
    private var descriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private let queue = DispatchQueue(
        label: "org.kiwix.directorymonitor",
        attributes: DispatchQueue.Attributes.concurrent
    )
    
    init(url: URL, onChange: (@Sendable (URL) -> Void)? = nil) {
        self.url = url
        self.onChange = onChange
    }
    
    // MARK: Monitoring
    
    func start() {
        guard source == nil && descriptor == -1 else { return }
        debugPrint("\(#file): \(url.path())")
        descriptor = open(url.path, O_EVTONLY)
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: .write,
            queue: queue
        )
        
        source?.setEventHandler(handler: {
            self.directoryContentDidChange()
        })
        source?.setCancelHandler(handler: {
            close(self.descriptor)
            self.descriptor = -1
            self.source = nil
        })
        source?.resume()
    }
    
    func stop() {
        guard let source = source else { return }
        source.cancel()
    }
    
    // MARK: - Custom Methods
    
    private var isCheckingChanges = false
    private var previousDirectoryHash: [String]?
    private var currentDirectoryHash: [String]?
    private var hashEqualCheck = 0
    
    private func directoryContentDidChange() {
        hashEqualCheck = 0
        if isCheckingChanges == false {
            checkDirectoryChanges()
        }
    }
    
    private func checkDirectoryChanges() {
        isCheckingChanges = true
        
        previousDirectoryHash = currentDirectoryHash
        currentDirectoryHash = directoryHashes()
        if let previousDirectoryHash = previousDirectoryHash, let currentDirectoryHash = currentDirectoryHash {
            if previousDirectoryHash == currentDirectoryHash {
                hashEqualCheck += 1
                if hashEqualCheck > 2 {
                    hashEqualCheck = 0
                    isCheckingChanges = false
                    self.previousDirectoryHash = nil
                    self.currentDirectoryHash = nil
                    directoryDidReachStasis()
                } else {
                    waitAndCheckAgain()
                }
            } else {
                hashEqualCheck = 0
                waitAndCheckAgain()
            }
        } else {
            checkDirectoryChanges()
        }
    }
    
    private func directoryDidReachStasis() {
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            onChange?(url)
        }
    }
    
    private func waitAndCheckAgain() {
        Task {
            try? await Task.sleep(nanoseconds: 50_000_000)
            checkDirectoryChanges()
        }
    }
    
    // MARK: - Generate directory file info array
    
    private func directoryHashes() -> [String] {
        var hashes = [String]()
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: url.path)
            for file in contents {
                if let hash = fileHash(file) {
                    hashes.append(hash)
                }
            }
        } catch let error as NSError {
            print("DirectoryMonitor: contentsOfDirectoryAtPath failed: \(error.localizedDescription)")
        }
        return hashes
    }
    
    private func fileHash(_ fileName: String) -> String? {
        if let fileSize = fileSize(fileName) {
            return fileName + "_\(fileSize)"
        } else {
            return nil
        }
    }
    
    private func fileSize(_ fileName: String) -> Int64? {
        let path = self.url.appendingPathComponent(fileName).path
        if FileManager.default.fileExists(atPath: path) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: path)
                let fileSize = attributes[FileAttributeKey.size] as? NSNumber
                return fileSize?.int64Value
            } catch let error as NSError {
                print("DirectoryMonitor: attributesOfItemAtPath failed: \(error.localizedDescription)")
            }
        }
        return nil
    }
}
