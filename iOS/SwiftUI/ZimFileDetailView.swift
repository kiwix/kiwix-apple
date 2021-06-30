//
//  ZimFileDetailView.swift
//  Kiwix
//
//  Created by Chris Li on 11/27/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import RealmSwift
import Defaults

/// Information and action about a single zim file in a list view.
@available(iOS 14.0, *)
struct ZimFileDetailView: View {
    @StateRealmObject private var zimFile: ZimFile
    @State private var showingAlert = false
    @Default(.libraryDownloadUsingCellular) private var libraryDownloadUsingCellular
    
    let hasEnoughDiskSpace: Bool
    let viewModel: ViewModel
    
    init(fileID: String) {
        if let database = try? Realm(), let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: fileID) {
            self._zimFile = StateRealmObject(wrappedValue: zimFile)
            self.hasEnoughDiskSpace = {
                guard let freeSpace = try? FileManager.default
                        .urls(for: .documentDirectory, in: .userDomainMask)
                        .first?.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                        .volumeAvailableCapacityForImportantUsage else { return false }
                return zimFile.size <= freeSpace
            }()
            self.viewModel = ViewModel(zimFile: zimFile)
        } else {
            self._zimFile = StateRealmObject(wrappedValue: ZimFile())
            self.hasEnoughDiskSpace = false
            self.viewModel = ViewModel(zimFile: ZimFile())
        }
    }
    
    var body: some View {
        List {
            Section {
                Text(zimFile.title)
                Text(zimFile.fileDescription)
            }
            Section {
                actions
            }
            Section {
                Cell(title: "Language", detail: Locale.current.localizedString(forLanguageCode: zimFile.languageCode))
                Cell(title: "Size", detail: zimFile.sizeDescription)
                Cell(title: "Date", detail: zimFile.creationDateDescription)
            }
            Section {
                CheckmarkCell(title: "Picture", isChecked: zimFile.hasPictures)
                CheckmarkCell(title: "Videos", isChecked: zimFile.hasVideos)
                CheckmarkCell(title: "Details", isChecked: zimFile.hasDetails)
            }
            Section {
                CountCell(title: "Article Count", count: zimFile.articleCount)
                CountCell(title: "Media Count", count: zimFile.mediaCount)
            }
            Section {
                Cell(title: "Creator", detail: zimFile.creator)
                Cell(title: "Publisher", detail: zimFile.publisher)
            }
            Section {
                Cell(title: "ID", detail: String(zimFile.fileID.prefix(8)))
            }
            if zimFile.state == .onDevice {
                Section {
                    ActionCell(
                        title: zimFile.openInPlaceURLBookmark == nil ? "Delete" : "Unlink",
                        isDestructive: true
                    ) { showingAlert = true }
                }
            }
        }
        .navigationTitle(zimFile.title)
        .listStyle(InsetGroupedListStyle())
        .alert(isPresented: $showingAlert) {
            if zimFile.openInPlaceURLBookmark == nil {
                return Alert(
                    title: Text("Delete Zim File"),
                    message: Text("The zim file will be deleted from the app's document directory."),
                    primaryButton: .destructive(Text("Delete"), action: {
                        LibraryService().deleteOrUnlink(fileID: zimFile.fileID)
                    }),
                    secondaryButton: .cancel()
                )
            } else {
                return Alert(
                    title: Text("Unlink Zim File"),
                    message: Text("The zim file will be unlinked from the app, but not deleted."),
                    primaryButton: .destructive(Text("Unlink"), action: {
                        LibraryService().deleteOrUnlink(fileID: zimFile.fileID)
                    }),
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    @ViewBuilder
    var actions: some View {
        switch zimFile.state {
        case .remote:
            if hasEnoughDiskSpace {
                Toggle("Cellular Data", isOn: $libraryDownloadUsingCellular)
                ActionCell(title: "Download") {
                    DownloadService.shared.start(
                        zimFileID: zimFile.fileID, allowsCellularAccess: libraryDownloadUsingCellular
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
            ZimFileDownloadDetailView(zimFile)
            cancelButton
        case .downloadInProgress:
            ZimFileDownloadDetailView(zimFile)
            ActionCell(title: "Pause") {
                DownloadService.shared.pause(zimFileID: zimFile.fileID)
            }
            cancelButton
        case .downloadPaused:
            ZimFileDownloadDetailView(zimFile)
            ActionCell(title: "Resume") {
                DownloadService.shared.resume(zimFileID: zimFile.fileID)
            }
            cancelButton
        case .downloadError:
            ZimFileDownloadDetailView(zimFile)
            cancelButton
        default:
            cancelButton
        }
    }
    
    var cancelButton: some View {
        ActionCell(title: "Cancel", isDestructive: true) { DownloadService.shared.cancel(zimFileID: zimFile.fileID) }
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
        
        static let countFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
        }()
        
        init(title: String, count: Int64?) {
            self.title = title
            self.count = count
        }
        
        var body: some View {
            HStack {
                Text(title)
                Spacer()
                if let count = count, let formatted = CountCell.countFormatter.string(from: NSNumber(value: count)) {
                    Text(formatted).foregroundColor(.secondary)
                } else {
                    Text("Unknown").foregroundColor(.secondary)
                }
            }
        }
    }
    
    class ViewModel: ObservableObject {
        private var zimFileObserver: NotificationToken?
        var onDelete: (() -> Void) = {}
        
        init(zimFile: ZimFile) {
            zimFileObserver = zimFile.observe { [unowned self] change in
                guard case .deleted = change else { return }
                self.onDelete()
            }
        }
    }
}
