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
struct ZimFileDetailView: View {
    @State private var showingAlert = false
    @ObservedObject var viewModel: ViewModel
    @Default(.libraryDownloadUsingCellular) private var libraryDownloadUsingCellular
    @ObservedResults(ZimFile.self) private var zimFiles
    
    init(fileID: String) {
        self.viewModel = ViewModel(fileID: fileID)
        self._zimFiles.filter = NSPredicate(format: "fileID == %@", fileID)
    }
    
    var body: some View {
        if let zimFile = zimFiles.first {
            List {
                Section {
                    Text(zimFile.title)
                    Text(zimFile.fileDescription)
                }
                Section {
                    actions
                }
                Section {
                    Cell(
                        title: "Language", detail: Locale.current.localizedString(forLanguageCode: zimFile.languageCode)
                    )
                    Cell(title: "Category", detail: zimFile.category.description)
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
            .insetGroupedListStyle()
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
        } else {
            Text("Zim file does not exist.")
        }
    }
    
    @ViewBuilder
    var actions: some View {
        if let zimFile = zimFiles.first {
            switch zimFile.state {
            case .remote:
                if viewModel.hasEnoughDiskSpace {
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
                    guard let zimFileID = UUID(uuidString: zimFile.fileID),
                          let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
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
    }
    
    var cancelButton: some View {
        ActionCell(title: "Cancel", isDestructive: true) {
            guard let fileID = zimFiles.first?.fileID else { return }
            DownloadService.shared.cancel(zimFileID: fileID)
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
        let hasEnoughDiskSpace: Bool
        var onDelete: (() -> Void) = {}
        private var zimFileObserver: NotificationToken?
        
        init(fileID: String) {
            guard let zimFile = (try? Realm())?.object(ofType: ZimFile.self, forPrimaryKey: fileID) else {
                self.hasEnoughDiskSpace = false
                return
            }
            self.hasEnoughDiskSpace = {
                guard let freeSpace = try? FileManager.default
                        .urls(for: .documentDirectory, in: .userDomainMask)
                        .first?.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                        .volumeAvailableCapacityForImportantUsage else { return false }
                return zimFile.size <= freeSpace
            }()
            zimFileObserver = zimFile.observe { [unowned self] change in
                guard case .deleted = change else { return }
                self.onDelete()
            }
        }
    }
}
