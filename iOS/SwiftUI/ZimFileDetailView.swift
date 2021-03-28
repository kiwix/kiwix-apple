//
//  ZimFileDetailView.swift
//  Kiwix
//
//  Created by Chris Li on 11/27/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

import RealmSwift

/// Display metadata about a zim file in a list view.
@available(iOS 14.0, *)
struct ZimFileDetailView: View {
    @StateRealmObject var zimFile: ZimFile
    @AppStorage("downloadUsingCellular") var downloadUsingCellular: Bool = false
    
    let hasEnoughDiskSpace: Bool
    
    init(fileID: String) {
        if let database = try? Realm(), let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: fileID) {
            self._zimFile = StateRealmObject(wrappedValue: zimFile)
            self.hasEnoughDiskSpace = {
                guard let freeSpace = try? FileManager.default
                        .urls(for: .documentDirectory, in: .userDomainMask)
                        .first?.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                        .volumeAvailableCapacityForImportantUsage,
                      let fileSize = zimFile.size.value else { return false }
                return fileSize <= freeSpace
            }()
        } else {
            self._zimFile = StateRealmObject(wrappedValue: ZimFile())
            self.hasEnoughDiskSpace = false
        }
    }
    
    var body: some View {
        List {
            Section {
                Text(zimFile.title)
                Text(zimFile.fileDescription)
            }
            actions
            Section {
                Cell(title: "Language", detail: zimFile.localizedLanguageName)
                Cell(title: "Size", detail: zimFile.sizeDescription)
                Cell(title: "Date", detail: zimFile.creationDateDescription)
            }
            Section {
                CheckmarkCell(title: "Picture", isChecked: zimFile.hasPictures)
                CheckmarkCell(title: "Videos", isChecked: zimFile.hasVideos)
                CheckmarkCell(title: "Details", isChecked: zimFile.hasDetails)
            }
            Section {
                CountCell(title: "Article Count", count: zimFile.articleCount.value)
                CountCell(title: "Media Count", count: zimFile.mediaCount.value)
            }
            Section {
                Cell(title: "Creator", detail: zimFile.creator)
                Cell(title: "Publisher", detail: zimFile.publisher)
            }
            Section {
                Cell(title: "ID", detail: String(zimFile.fileID.prefix(8)))
            }
        }
        .navigationTitle(zimFile.title)
        .listStyle(InsetGroupedListStyle())
    }
    
    var actions: some View {
        Section {
            switch zimFile.state {
            case .remote:
                if hasEnoughDiskSpace {
                    Toggle("Cellular Data", isOn: $downloadUsingCellular)
                    ActionCell(title: "Download") {
                        DownloadService.shared.start(
                            zimFileID: zimFile.fileID, allowsCellularAccess: downloadUsingCellular
                        )
                    }
                } else {
                    ActionCell(title: "Download - Not Enough Space").disabled(true)
                }
            case .onDevice:
                ActionCell(title: "Open Main Page", isDestructive: false) {
                    guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID) else { return }
                    UIApplication.shared.open(url)
                }
            case .downloadQueued:
                Text("Queued")
                cancelButton
            case .downloadInProgress:
                Cell(title: "Downloading...",
                     detail: [
                        zimFile.downloadedSizeDescription, zimFile.downloadedPercentDescription
                     ].compactMap({ $0 }).joined(separator: " - ")
                )
                ActionCell(title: "Pause") {
                    DownloadService.shared.pause(zimFileID: zimFile.fileID)
                }
                cancelButton
            case .downloadPaused:
                Cell(title: "Paused",
                     detail: [
                        zimFile.downloadedSizeDescription, zimFile.downloadedPercentDescription
                     ].compactMap({ $0 }).joined(separator: " - ")
                )
                ActionCell(title: "Resume") {
                    DownloadService.shared.resume(zimFileID: zimFile.fileID)
                }
                cancelButton
            case .downloadError:
                Text("Error")
                if let errorDescription = zimFile.downloadErrorDescription {
                    Text(errorDescription)
                }
                cancelButton
            default:
                cancelButton
            }
        }
    }
    
    var cancelButton: some View {
            ActionCell(title: "Cancel", isDestructive: true) {
                DownloadService.shared.cancel(zimFileID: zimFile.fileID)
            }
        }
    
    struct Cell: View {
        let title: String
        let detail: String?
        
        var body: some View {
            HStack {
                Text(title)
                Spacer()
                Text(detail ?? "Unknown").foregroundColor(.secondary)
            }
        }
    }
    
    struct ActionCell: View {
        let title: String
        let isDestructive: Bool
        let action: (() -> Void)
        
        init(title: String, isDestructive: Bool = false, action: @escaping (() -> Void) = {}) {
            self.title = title
            self.isDestructive = isDestructive
            self.action = action
        }
        
        var body: some View {
            Button(action: action, label: {
                HStack {
                    Spacer()
                    Text(title)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? .red : nil)
                    Spacer()
                }
            })
        }
    }
    
    struct CheckmarkCell: View {
        let title: String
        let isChecked: Bool
        
        var body: some View {
            HStack {
                Text(title)
                Spacer()
                if isChecked{
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                } else {
                    Image(systemName: "multiply.circle.fill").foregroundColor(.secondary)
                }
            }
        }
    }
    
    struct CountCell: View {
        let title: String
        let count: Int64?
        
        init(title: String, count: Int64?) {
            self.title = title
            self.count = count
        }
        
        var body: some View {
            HStack {
                Text(title)
                Spacer()
                if let count = count, let formatted = ZimFile.countFormatter.string(from: NSNumber(value: count)) {
                    Text(formatted).foregroundColor(.secondary)
                } else {
                    Text("Unknown").foregroundColor(.secondary)
                }
            }
        }
    }
}
