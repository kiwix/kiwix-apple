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
import OSLog

enum Diagnostics {
    
    private static let byteCountFormatter = ByteCountFormatter()
    
    /// Log the os and app related infos
    static func start() {
        Log.Environment.notice("app: \(appVersion(), privacy: .public)")
        Log.Environment.notice("os: \(osName(), privacy: .public)")
        Log.Environment.notice("free space: \(freeSpace(), privacy: .public)")
#if os(macOS)
        MacUser.name()
        MacUser.logIsUserAdmin()
        DownloadDiagnostics.path()
#endif
        Log.Environment.notice("\(languageCurrent(), privacy: .public)")
        Log.Environment.notice("\(libraryLanguageCodes(), privacy: .public)")
        
    }
    
    static func entries(separator: String) async -> String {
        guard let logStore = try? OSLogStore(scope: .currentProcessIdentifier),
              let entries = try? logStore.getEntries(
                matching: NSPredicate(format: "subsystem == %@", KiwixLogger.subsystem)
              ) else {
            Log.Environment.error("couldn't collect logs")
            return ""
        }
        
        var logs: String = ""
        for entry in entries.makeIterator() {
            logs = logs.appending("\(entry.date.ISO8601Format()); \(entry.composedMessage)\(separator)")
        }
        return logs
    }
    
    private static func appVersion() -> String {
        let unknown = "unknown"
        let bundle = Bundle.main
        let infoDict = bundle.infoDictionary
        
        let bundleIdentifier = bundle.bundleIdentifier ?? unknown
        let releaseVersion = (infoDict?["CFBundleShortVersionString"] as? String) ?? unknown
        let buildNumber = (infoDict?["CFBundleVersion"] as? String) ?? unknown
        
        return "\(bundleIdentifier): \(releaseVersion) (\(buildNumber))"
    }
    
    private static func osName() -> String {
        let deviceType = Device.current.rawValue
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        return "\(deviceType): \(osVersion)"
    }
    
    private static func languageCurrent() -> String {
        let current = Locale.current.language.languageCode?.identifier ?? "unknown"
        return "Current language: \(current)"
    }
    
    private static func libraryLanguageCodes() -> String {
        let languageCodes: Set<String> = Defaults[.libraryLanguageCodes]
        return "Library language codes: \(languageCodes.joined(separator: ", "))"
    }
    
    private static func freeSpace() -> String {
        
        let freeSpace: Int64? = try? FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            .volumeAvailableCapacityForImportantUsage
        
        guard let freeSpace else {
            return "unknown"
        }
        return byteCountFormatter.string(fromByteCount: freeSpace)
    }
}
