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
import Combine
import SwiftUI

struct DiagnosticItem: Identifiable {
    let id: Identifier
    var title: String
    var status: Status
    
    init(id: Identifier, title: String? = nil, status: Status = .initial) {
        self.id = id
        if let title {
            self.title = title
        } else {
            self.title = id.defaultTitle
        }
        self.status = status
    }
    
    enum Status {
        case initial
        case inProgress
        case complete
        
        var isComplete: Bool {
            self == .complete
        }
        
        var systemImage: String {
            switch self {
            case .initial: "circle"
            case .inProgress: "circle.dashed"
            case .complete: "checkmark.circle.fill"
            }
        }
        var tintColor: Color {
            switch self {
            case .initial: .gray
            case .inProgress: .orange
            case .complete: .green
            }
        }
    }
    
    enum Identifier {
        case integrityCheck
        case applicationLogs
        case languageSettings
        case listOfZimFiles
        case deviceDetails
        case fileSystemDetails
        
        var defaultTitle: String {
            switch self {
            case .integrityCheck: "Integrity check of ZIM files"
            case .applicationLogs: "Application logs"
            case .languageSettings: "Your language settings"
            case .listOfZimFiles: "List of your ZIM files"
            case .deviceDetails: "Device details"
            case .fileSystemDetails: "File system details"
            }
        }
    }
}

final class DiagnosticsModel: ObservableObject {
    
    @MainActor @Published
    var items: [DiagnosticItem] = [
        DiagnosticItem(id: .integrityCheck),
        DiagnosticItem(id: .applicationLogs),
        DiagnosticItem(id: .languageSettings),
        DiagnosticItem(id: .deviceDetails),
        DiagnosticItem(id: .fileSystemDetails),
        DiagnosticItem(id: .listOfZimFiles),
    ]
    
    private var integrityModel = ZimIntegrityModel()
    private var cancellable: AnyCancellable?
    
    func start(using zimFiles: [ZimFile]) async -> [String] {
        await updateItemBy(id: .integrityCheck, status: .inProgress)
        cancellable = await integrityModel.checks.publisher.sink(receiveCompletion: { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.completeItegrityCheck()
            }
        }, receiveValue: { checkInfo in
            Task { @MainActor [weak self] in
                let title = LocalString.zim_file_integrity_check_in_progress(withArgs: checkInfo.zimFile.name)
                self?.integrityCheckProgress(title: title)
            }
        })
        await integrityModel.check(zimFiles: zimFiles)

        await updateItemBy(id: .applicationLogs, status: .inProgress)
        let entries = await Diagnostics.entriesSeparated()
        await updateItemBy(id: .languageSettings, status: .complete)
        await updateItemBy(id: .deviceDetails, status: .complete)
        await updateItemBy(id: .fileSystemDetails, status: .complete)
        return entries
    }
    
    @MainActor
    private func integrityCheckProgress(title: String) {
        items = items.map { item in
            if item.id == .integrityCheck {
                var newItem = item
                newItem.title = title
                newItem.status = .inProgress
                return newItem
            } else {
                return item
            }
        }
    }
    
    @MainActor
    private func completeItegrityCheck() {
        items = items.map { item in
            if item.id == .integrityCheck {
                var newItem = item
                newItem.title = DiagnosticItem.Identifier.integrityCheck.defaultTitle
                newItem.status = .complete
                return newItem
            } else {
                return item
            }
        }
    }
    
    @MainActor
    private func updateItemBy(id: DiagnosticItem.Identifier, status: DiagnosticItem.Status) {
        items = items.map { item in
            if item.id == id {
                var newItem = item
                newItem.status = status
                return newItem
            } else {
                return item
            }
        }
    }
}

enum Diagnostics {
    
    private static let byteCountFormatter = ByteCountFormatter()
    
    /// Log the os and app related infos
    static func start() {
        Log.Environment.notice("app: \(appVersion(), privacy: .public)")
        Log.Environment.notice("os: \(osName(), privacy: .public)")
        Log.Environment.notice("free space: \(freeSpace(), privacy: .public)")
        Log.Environment.notice("\(languageCurrent(), privacy: .public)")
        Log.Environment.notice("\(libraryLanguageCodes(), privacy: .public)")
    }
    
    static func entriesSeparated() async -> [String] {
#if os(macOS)
        MacUser.name()
        MacUser.isUserAdmin()
#endif
        Log.Environment.notice("ProcessInfo.environment:\n\(processInfoEnvironment(), privacy: .public)")
        DownloadDiagnostics.path()
        DownloadDiagnostics.testWritingAFile()
        
        guard let logStore = try? OSLogStore(scope: .currentProcessIdentifier),
              let entries = try? logStore.getEntries(
                matching: NSPredicate(format: "subsystem == %@", KiwixLogger.subsystem)
              ) else {
            Log.Environment.error("couldn't collect logs")
            return []
        }
        
        var logs: [String] = []
        for entry in entries.makeIterator() {
            logs.append("\(entry.date.ISO8601Format()); \(entry.composedMessage)")
        }
        return logs
    }
    
    static func entries(separator: String) async -> String {
#if os(macOS)
        MacUser.name()
        MacUser.isUserAdmin()
#endif
        Log.Environment.notice("ProcessInfo.environment:\n\(processInfoEnvironment(), privacy: .public)")
        DownloadDiagnostics.path()
        DownloadDiagnostics.testWritingAFile()
        
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
    
    public static func fileName(using date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withDashSeparatorInDate, .withFullDate]
        let dateString = formatter.string(from: date)
        return "kiwix_diagnostic_\(dateString)"
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
    
    private static func processInfoEnvironment() -> String {
        var result = "[\n"
        let environment = ProcessInfo().environment
        for key in environment.keys.sorted() {
            let value = environment[key] ?? "null"
            result.append("\(key): \(value)\n")
        }
        return result.appending("]")
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
