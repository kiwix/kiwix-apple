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

#if os(macOS)
import Foundation

/// Represents the persistent state of a direct-write download on macOS.
/// This state is saved to disk to allow resuming downloads after app restart or crash.
struct DirectWriteDownloadState: Codable {
    /// Unique identifier for the ZIM file being downloaded
    let zimFileID: UUID
    
    /// The source URL to download from
    let downloadURL: URL
    
    /// The full path where the file is being written
    let destinationURL: URL
    
    /// Number of bytes successfully written to disk
    var bytesWritten: Int64
    
    /// Expected total size of the file (from Content-Length header)
    let expectedTotalBytes: Int64
    
    /// Whether the download is currently paused
    var isPaused: Bool
    
    /// Timestamp of last successful write (for timeout detection)
    var lastWriteTime: Date
    
    /// ETag from the server response (for validation on resume)
    var serverETag: String?
    
    /// Last-Modified header from server (for validation on resume)
    var serverLastModified: String?
    
    // MARK: - Computed Properties
    
    /// Progress as a fraction from 0.0 to 1.0
    var progress: Double {
        guard expectedTotalBytes > 0 else { return 0 }
        return Double(bytesWritten) / Double(expectedTotalBytes)
    }
    
    /// Whether the download is complete
    var isComplete: Bool {
        bytesWritten >= expectedTotalBytes && expectedTotalBytes > 0
    }
    
    /// Remaining bytes to download
    var remainingBytes: Int64 {
        max(0, expectedTotalBytes - bytesWritten)
    }
    
    // MARK: - Initialization
    
    init(
        zimFileID: UUID,
        downloadURL: URL,
        destinationURL: URL,
        expectedTotalBytes: Int64
    ) {
        self.zimFileID = zimFileID
        self.downloadURL = downloadURL
        self.destinationURL = destinationURL
        self.bytesWritten = 0
        self.expectedTotalBytes = expectedTotalBytes
        self.isPaused = false
        self.lastWriteTime = Date()
        self.serverETag = nil
        self.serverLastModified = nil
    }
    
    // MARK: - State Updates
    
    /// Creates a new state with updated bytes written
    func withBytesWritten(_ bytes: Int64) -> DirectWriteDownloadState {
        var newState = self
        newState.bytesWritten = bytes
        newState.lastWriteTime = Date()
        return newState
    }
    
    /// Creates a new state with paused flag toggled
    func withPaused(_ paused: Bool) -> DirectWriteDownloadState {
        var newState = self
        newState.isPaused = paused
        return newState
    }
    
    /// Creates a new state with server validation headers
    func withServerHeaders(eTag: String?, lastModified: String?) -> DirectWriteDownloadState {
        var newState = self
        newState.serverETag = eTag
        newState.serverLastModified = lastModified
        return newState
    }
}

// MARK: - State Persistence

extension DirectWriteDownloadState {
    /// Key prefix for storing download states in UserDefaults
    private static let stateKeyPrefix = "directWriteDownloadState_"
    
    /// Returns the UserDefaults key for a given ZIM file ID
    private static func stateKey(for zimFileID: UUID) -> String {
        "\(stateKeyPrefix)\(zimFileID.uuidString)"
    }
    
    /// Saves this state to UserDefaults
    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: Self.stateKey(for: zimFileID))
            Log.DownloadService.debug(
                "Saved direct-write state for \(zimFileID.uuidString, privacy: .public): \(bytesWritten) bytes"
            )
        } catch {
            Log.DownloadService.error(
                "Failed to save direct-write state: \(error.localizedDescription, privacy: .public)"
            )
        }
    }
    
    /// Loads a download state from UserDefaults
    /// - Parameter zimFileID: The ZIM file ID to load state for
    /// - Returns: The saved state, or nil if not found
    static func load(for zimFileID: UUID) -> DirectWriteDownloadState? {
        guard let data = UserDefaults.standard.data(forKey: stateKey(for: zimFileID)) else {
            return nil
        }
        
        do {
            let state = try JSONDecoder().decode(DirectWriteDownloadState.self, from: data)
            Log.DownloadService.debug(
                "Loaded direct-write state for \(zimFileID.uuidString, privacy: .public): \(state.bytesWritten) bytes"
            )
            return state
        } catch {
            Log.DownloadService.error(
                "Failed to load direct-write state: \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }
    
    /// Removes the saved state for a ZIM file
    /// - Parameter zimFileID: The ZIM file ID to remove state for
    static func remove(for zimFileID: UUID) {
        UserDefaults.standard.removeObject(forKey: stateKey(for: zimFileID))
        Log.DownloadService.debug(
            "Removed direct-write state for \(zimFileID.uuidString, privacy: .public)"
        )
    }
    
    /// Returns all saved direct-write download states
    static func loadAll() -> [DirectWriteDownloadState] {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let stateKeys = allKeys.filter { $0.hasPrefix(stateKeyPrefix) }
        
        return stateKeys.compactMap { key -> DirectWriteDownloadState? in
            guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(DirectWriteDownloadState.self, from: data)
        }
    }
}

// MARK: - File Validation

extension DirectWriteDownloadState {
    /// Validates that the partial file on disk matches the saved state
    /// - Returns: true if the file exists and its size matches bytesWritten
    func validatePartialFile() -> Bool {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: destinationURL.path) else {
            Log.DownloadService.warning(
                "Partial file does not exist: \(destinationURL.path, privacy: .public)"
            )
            return false
        }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
            guard let fileSize = attributes[.size] as? Int64 else {
                return false
            }
            
            if fileSize >= bytesWritten {
                return true
            } else {
                Log.DownloadService.warning(
                    """
                    Partial file size mismatch: expected \(bytesWritten), \
                    got \(fileSize) at \(destinationURL.path, privacy: .public)
                    """
                )
                return false
            }
        } catch {
            Log.DownloadService.error(
                "Failed to get file attributes: \(error.localizedDescription, privacy: .public)"
            )
            return false
        }
    }
}
#endif
