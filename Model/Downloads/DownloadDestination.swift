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

enum DownloadDestination {
    
    // MARK: - Default Directory
    
    /// Returns the default download directory based on platform.
    /// - macOS: ~/Downloads
    /// - iOS: App's Documents directory
    static func downloadLocalFolder() -> URL? {
        #if os(macOS)
        let searchPath = FileManager.SearchPathDirectory.downloadsDirectory
        #elseif os(iOS)
        let searchPath = FileManager.SearchPathDirectory.documentDirectory
        #endif

        guard let directory = FileManager.default.urls(for: searchPath, in: .userDomainMask).first else {
            Log.DownloadService.fault(
                "Cannot find download directory!"
            )
            return nil
        }
        return directory
    }
    
    // MARK: - macOS Custom Directory Support
    
    #if os(macOS)
    /// Returns the effective download directory on macOS.
    /// If a custom directory is set and accessible, returns that.
    /// Otherwise, falls back to the default Downloads folder.
    static func effectiveDownloadFolder() -> URL? {
        if let customURL = customDownloadDirectory() {
            // Verify the directory still exists and is accessible
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: customURL.path, isDirectory: &isDirectory),
               isDirectory.boolValue {
                return customURL
            } else {
                Log.DownloadService.warning(
                    "Custom download directory no longer accessible: \(customURL.path, privacy: .public)"
                )
                // Clear the invalid bookmark
                clearCustomDownloadDirectory()
            }
        }
        return downloadLocalFolder()
    }
    
    /// Retrieves the custom download directory from stored bookmark data.
    /// Uses security-scoped bookmarks to maintain access across app restarts.
    static func customDownloadDirectory() -> URL? {
        guard let bookmarkData = Defaults[.downloadDirectoryBookmark] else {
            return nil
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                Log.DownloadService.info("Bookmark data is stale, attempting to refresh")
                // Try to create a new bookmark
                if let newBookmark = try? url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                ) {
                    Defaults[.downloadDirectoryBookmark] = newBookmark
                }
            }
            
            return url
        } catch {
            Log.DownloadService.error(
                "Failed to resolve bookmark data: \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }
    
    /// Saves a custom download directory as a security-scoped bookmark.
    /// - Parameter url: The directory URL to save
    /// - Returns: true if the bookmark was saved successfully
    @discardableResult
    static func setCustomDownloadDirectory(_ url: URL) -> Bool {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            Defaults[.downloadDirectoryBookmark] = bookmarkData
            Log.DownloadService.info(
                "Custom download directory set to: \(url.path, privacy: .public)"
            )
            return true
        } catch {
            Log.DownloadService.error(
                "Failed to create bookmark for directory: \(error.localizedDescription, privacy: .public)"
            )
            return false
        }
    }
    
    /// Clears the custom download directory, reverting to default.
    static func clearCustomDownloadDirectory() {
        Defaults[.downloadDirectoryBookmark] = nil
        Log.DownloadService.info("Custom download directory cleared")
    }
    
    /// Checks if a custom download directory is currently set.
    static var hasCustomDownloadDirectory: Bool {
        Defaults[.downloadDirectoryBookmark] != nil
    }
    
    /// Checks whether direct-write downloads should be used.
    /// Direct-write is used on macOS when a custom directory is set.
    static var shouldUseDirectWrite: Bool {
        hasCustomDownloadDirectory
    }
    #endif
    
    // MARK: - File Path Generation
    
    /// Returns the full file path for a download URL.
    /// On macOS, this uses the effective directory (custom or default).
    /// On iOS, this uses the Documents directory.
    static func filePathFor(downloadURL: URL) -> URL? {
        #if os(macOS)
        return effectiveDownloadFolder()?.appendingPathComponent(downloadURL.lastPathComponent)
        #else
        return downloadLocalFolder()?.appendingPathComponent(downloadURL.lastPathComponent)
        #endif
    }
    
    /// Generates an alternate file path when a file already exists.
    /// Appends a number suffix (e.g., "file-2.zim", "file-3.zim").
    static func alternateLocalPathFor(downloadURL url: URL, count: Int) -> URL {
        guard count > 0 else {
            return url
        }
        let fileName = url.deletingPathExtension().lastPathComponent
        let newFileName = fileName.appending("-\(count + 1)")
        return url
            .deletingLastPathComponent()
            .appendingPathComponent(newFileName, conformingTo: .zimFile)
    }
    
    // MARK: - Destination Validation
    
    #if os(macOS)
    /// Result of validating a download destination.
    enum ValidationResult {
        case valid
        case notAccessible
        case insufficientSpace(required: Int64, available: Int64)
        case notWritable
    }
    
    /// Validates that a destination directory is suitable for downloading a file.
    /// - Parameters:
    ///   - directory: The directory to validate
    ///   - requiredBytes: The size of the file to be downloaded
    /// - Returns: A ValidationResult indicating whether the directory is valid
    static func validateDestination(directory: URL, requiredBytes: Int64) -> ValidationResult {
        let fileManager = FileManager.default

        let needsScope = directory.startAccessingSecurityScopedResource()
        defer { if needsScope { directory.stopAccessingSecurityScopedResource() } }

        // Check if directory exists and is accessible
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return .notAccessible
        }

        // Check if we can write to the directory
        guard fileManager.isWritableFile(atPath: directory.path) else {
            return .notWritable
        }

        // Check available disk space
        do {
            let resourceValues = try directory.resourceValues(
                forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey]
            )
            let availableSpace: Int64
            // Prefer APFS-aware key (accounts for purgeable space)
            if let space = resourceValues.volumeAvailableCapacityForImportantUsage, space > 0 {
                availableSpace = space
            // Fallback for ExFAT, HFS+, NTFS, and other non-APFS filesystems
            } else if let space = resourceValues.volumeAvailableCapacity {
                availableSpace = Int64(space)
            } else {
                return .valid  // Cannot determine space, allow download
            }
            // Add 100MB safety margin
            let safetyMargin: Int64 = 100 * 1024 * 1024
            if availableSpace < requiredBytes + safetyMargin {
                return .insufficientSpace(required: requiredBytes, available: availableSpace)
            }
        } catch {
            Log.DownloadService.warning(
                "Could not determine available disk space: \(error.localizedDescription, privacy: .public)"
            )
            // Proceed anyway - the error will be caught during download if space runs out
        }

        return .valid
    }
    
    /// Returns the available disk space at the effective download directory.
    /// - Returns: Available bytes, or nil if it cannot be determined
    static func availableDiskSpace() -> Int64? {
        guard let directory = effectiveDownloadFolder() else { return nil }

        let needsScope = directory.startAccessingSecurityScopedResource()
        defer { if needsScope { directory.stopAccessingSecurityScopedResource() } }

        do {
            let resourceValues = try directory.resourceValues(
                forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey]
            )
            // Prefer APFS-aware key (accounts for purgeable space)
            if let available = resourceValues.volumeAvailableCapacityForImportantUsage, available > 0 {
                return available
            }
            // Fallback for ExFAT, HFS+, NTFS, and other non-APFS filesystems
            if let available = resourceValues.volumeAvailableCapacity {
                return Int64(available)
            }
            return nil
        } catch {
            Log.DownloadService.warning(
                "Could not determine available disk space: \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }
    
    /// Returns the volume name for the effective download directory.
    /// Useful for displaying to the user which volume downloads will go to.
    static func volumeName() -> String? {
        guard let directory = effectiveDownloadFolder() else { return nil }

        let needsScope = directory.startAccessingSecurityScopedResource()
        defer { if needsScope { directory.stopAccessingSecurityScopedResource() } }

        return try? directory.resourceValues(forKeys: [.volumeNameKey]).volumeName
    }
    #endif
}
