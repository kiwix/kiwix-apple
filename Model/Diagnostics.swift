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
import OSLog

enum Diagnostics {
    
    /// Log the os and app related infos
    static func start() {
        Log.Environment.notice("app: \(appVersion())")
        Log.Environment.notice("os: \(osName())")
    }
    
    static func entries() async {
        guard let logStore = try? OSLogStore(scope: .currentProcessIdentifier),
              let entries = try? logStore.getEntries(
                matching: NSPredicate(format: "subsystem == %@", KiwixLogger.subsystem)
              ) else {
            Log.Environment.error("couldn't collect logs")
            return
        }
        
        for entry in entries.makeIterator() {
            print("\(entry.date.ISO8601Format()); \(entry.composedMessage)")
        }
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
}
