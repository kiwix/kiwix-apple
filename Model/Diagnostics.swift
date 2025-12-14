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

struct DiagnosticItem: Identifiable, Equatable {
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
    
    enum Status: Equatable {
        case initial
        case inProgress
        case complete(Bool)
        
        var isComplete: Bool {
            if case .complete = self {
                return true
            }
            return false
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
        
        static func from(checkState: ZimIntegrityModel.CheckState) -> Self {
            switch checkState {
            case .enqued: Status.initial
            case .running: Status.inProgress
            case .complete(let isValid): Status.complete(isValid)
            }
        }
    }
    
    enum Identifier: Hashable {
        case integrityCheck
        case integrityZIM(UUID)
        case applicationLogs
        case languageSettings
        case listOfZimFiles
        case deviceDetails
        case fileSystemDetails
        
        var defaultTitle: String {
            switch self {
            case .integrityCheck: "Integrity check of ZIM files"
            case .integrityZIM: "Integrity check of ZIM files"
            case .applicationLogs: "Application logs"
            case .languageSettings: "Your language settings"
            case .listOfZimFiles: "List of your ZIM files"
            case .deviceDetails: "Device details"
            case .fileSystemDetails: "File system details"
            }
        }
    }
}

private enum Const {
    static let defaultItems: [DiagnosticItem] = [
        DiagnosticItem(id: .listOfZimFiles),
        DiagnosticItem(id: .integrityCheck),
        DiagnosticItem(id: .applicationLogs),
        DiagnosticItem(id: .languageSettings),
        DiagnosticItem(id: .deviceDetails),
        DiagnosticItem(id: .fileSystemDetails),
    ]
}

final class DiagnosticsModel: ObservableObject {
    
    @MainActor @Published
    var items: [DiagnosticItem] = Const.defaultItems
    
    private var integrityModel = ZimIntegrityModel()
    private var cancellable: AnyCancellable?
    
    func cancel() {
        Task { @MainActor in
            items = Const.defaultItems
            integrityModel.reset()
            cancellable?.cancel()
            integrityModel = ZimIntegrityModel()
        }
    }
    
    func start(using zimFiles: [ZimFile]) async -> [String] {
        await updateItemBy(id: .listOfZimFiles, status: .complete(true))
        await updateItemBy(id: .integrityCheck, status: .inProgress)
        cancellable = integrityModel.$checks.sink(receiveValue: { [weak self] (infos: [ZimIntegrityModel.Info]) in
            self?.didReceive(checkInfos: infos)
        })
        
        await integrityModel.check(zimFiles: zimFiles)
        guard !Task.isCancelled else { return [] }
        await updateItemBy(id: .applicationLogs, status: .inProgress)
        guard !Task.isCancelled else { return [] }
        let entries = await Diagnostics.entriesSeparated()
        guard !Task.isCancelled else { return [] }
        await updateItemBy(id: .applicationLogs, status: .complete(true))
        await updateItemBy(id: .languageSettings, status: .complete(true))
        await updateItemBy(id: .deviceDetails, status: .complete(true))
        await updateItemBy(id: .fileSystemDetails, status: .complete(true))
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
    
    private func didReceive(checkInfos: [ZimIntegrityModel.Info]) {
        Task { @MainActor [weak self] in
            guard var items = self?.items else { return }
            if let integrityIndex = items.firstIndex(where: { $0.id == .integrityCheck }) {
                items.remove(at: integrityIndex)
            }
            for check in checkInfos {
                if let index = items.firstIndex(where: { $0.id == .integrityZIM(check.id) } ) {
                    var item: DiagnosticItem = items[index]
                    item.status = .from(checkState: check.state)
                    items[index] = item
                } else {
                    let newItem = DiagnosticItem(id: .integrityZIM(check.id),
                                                 title: LocalString.zim_file_integrity_check_in_progress(withArgs: check.zimFile.name),
                                                 status: .from(checkState: check.state))
                    let insertIndex: Int = items.firstIndex(where: { $0.id == .applicationLogs }) ?? 0
                    items.insert(newItem, at: insertIndex)
                }
            }
            self?.items = items
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
