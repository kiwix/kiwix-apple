//
//  ZimFileDetailView.swift
//  Kiwix
//
//  Created by Chris Li on 11/27/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

import RealmSwift

@available(iOS 14.0, *)
struct ZimFileDetailView: View {
    @StateRealmObject var zimFile: ZimFile
    
    init(fileID: String) {
        if let database = try? Realm(), let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: fileID) {
            self._zimFile = StateRealmObject(wrappedValue: zimFile)
        } else {
            self._zimFile = StateRealmObject(wrappedValue: ZimFile())
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
                if true {
//                    Toggle("Cellular Data", isOn: downloadUsingCellular)
                    ActionButton(title: "Download") {
                        DownloadService.shared.start(
                            zimFileID: zimFile.fileID, allowsCellularAccess: true
                        )
                    }
                } else {
                    ActionButton(title: "Download - Not Enough Space").disabled(true)
                }
            case .onDevice:
                ActionButton(title: "Open Main Page", isDestructive: false) {
//                    openMainPage(zimFile.id)
                }
            case .downloadQueued:
                Text("Queued")
                cancelButton
            case .downloadInProgress:
//                if #available(iOS 14.0, *), let progress = viewModel.downloadProgress {
//                    ProgressView(progress)
//                } else {
//                    Text("Downloading...")
//                }
                ProgressView("Downloading...", value: Double(zimFile.downloadTotalBytesWritten), total: Double(zimFile.size.value ?? 0))
                .progressViewStyle(CircularProgressViewStyle())
                ActionButton(title: "Pause") {
                    DownloadService.shared.pause(zimFileID: zimFile.fileID)
                }
                cancelButton
            case .downloadPaused:
                HStack {
                    Text("Paused")
//                    if let progress = viewModel.downloadProgress {
//                        Spacer()
//                        Text(progress.localizedAdditionalDescription)
//                    }
                }
                ActionButton(title: "Resume") {
                    DownloadService.shared.resume(zimFileID: zimFile.fileID)
                }
                cancelButton
            case .downloadError:
                Text("Error")
                if let errorDescription = zimFile.downloadErrorDescription {
                    Text(errorDescription)
                }
            default:
                cancelButton
            }
        }
    }
    
    var cancelButton: some View {
            ActionButton(title: "Cancel", isDestructive: true) {
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
    
    struct CountCell: View {
        let title: String
        let count: Int64?
        private let formatter = NumberFormatter()
        
        init(title: String, count: Int64?) {
            self.title = title
            self.count = count
            formatter.numberStyle = .decimal
        }
        
        var body: some View {
            HStack {
                Text(title)
                Spacer()
                if let count = count, let formatted = NumberFormatter().string(from: NSNumber(value: count)) {
                    Text(formatted).foregroundColor(.secondary)
                } else {
                    Text("Unknown").foregroundColor(.secondary)
                }
            }
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
    
    struct ActionButton: View {
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
}
