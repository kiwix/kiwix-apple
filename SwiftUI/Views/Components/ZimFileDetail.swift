//
//  ZimFileDetail.swift
//  Kiwix
//
//  Created by Chris Li on 4/30/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI
import UniformTypeIdentifiers

import Defaults

/// Detail about one single zim file.
struct ZimFileDetail: View {
    @Binding var url: URL?
    @Default(.downloadUsingCellular) private var downloadUsingCellular
    @EnvironmentObject private var viewModel: ViewModel
    @EnvironmentObject private var libraryViewModel: LibraryViewModel
    @ObservedObject var zimFile: ZimFile
    @State private var isPresentingDeleteAlert = false
    @State private var isPresentingDownloadAlert = false
    @State private var isPresentingFileLocator = false
    @State private var isPresentingUnlinkAlert = false
    
    var body: some View {
        #if os(macOS)
        List {
            Section("Name") { Text(zimFile.name).lineLimit(nil) }.collapsible(false)
            Section("Description") { Text(zimFile.fileDescription).lineLimit(nil) }.collapsible(false)
            Section("Actions") { actions }.collapsible(false)
            Section("Info") {
                basicInfo
                boolInfo
                counts
                id
            }.collapsible(false)
        }
        .safeAreaInset(edge: .top) {
            if zimFile.requiresServiceWorkers {
                VStack(spacing: 0) {
                    ServiceWorkerWarning().padding(6)
                    Divider()
                }.background(.regularMaterial)
            }
        }
        .listStyle(.sidebar)
        .modifier(FileLocator(isPresenting: $isPresentingFileLocator))
        #elseif os(iOS)
        List {
            Section {
                Text(zimFile.name).lineLimit(nil)
                Text(zimFile.fileDescription).lineLimit(nil)
            }
            Section {
                if #available(iOS 16.0, *) {
                    actions.alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
                } else {
                    actions
                }
            }
            Section { basicInfo }
            Section {
                boolInfo
            } footer: {
                if zimFile.requiresServiceWorkers {
                    ServiceWorkerWarning()
                }
            }
            Section { counts }
            Section { id }
        }
        .listStyle(.insetGrouped)
        .modifier(FileLocator(isPresenting: $isPresentingFileLocator))
        .navigationTitle(zimFile.name)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    @ViewBuilder
    var actions: some View {
        if let downloadTask = zimFile.downloadTask {  // zim file is being downloaded
            DownloadTaskDetail(downloadTask: downloadTask)
        } else if zimFile.isMissing {  // zim file was opened, but is now missing
            Action(title: "Locate") { isPresentingFileLocator = true }
            unlinkAction
        } else if zimFile.fileURLBookmark != nil {  // zim file is opened
            Action(title: "Open Main Page") {
                url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID)
                viewModel.navigationItem = .reading
            }
            #if os(macOS)
            Action(title: "Reveal in Finder") {
                guard let url = ZimFileService.shared.getFileURL(zimFileID: zimFile.id) else { return }
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
            unlinkAction
            #elseif os(iOS)
            if let zimFileName = ZimFileService.shared.getFileURL(zimFileID: zimFile.fileID)?.lastPathComponent,
               let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
               FileManager.default.fileExists(atPath: documentDirectoryURL.appendingPathComponent(zimFileName).path) {
                deleteAction
            } else {
                unlinkAction
            }
            #endif
        } else if zimFile.downloadURL != nil {  // zim file can be downloaded
            #if os(iOS)
            Toggle("Download using cellular", isOn: $downloadUsingCellular)
            #endif
            downloadAction
        }
    }
    
    var unlinkAction: some View {
        Action(title: "Unlink", isDestructive: true) {
            isPresentingUnlinkAlert = true
        }.alert(isPresented: $isPresentingUnlinkAlert) {
            Alert(
                title: Text("Unlink \(zimFile.name)"),
                message: Text("""
                All bookmarked articles linked to this zim file will be deleted, \
                but the original file will remain in place.
                """),
                primaryButton: .destructive(Text("Unlink")) {
                    LibraryViewModel.unlink(zimFileID: zimFile.fileID)
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    var deleteAction: some View {
        Action(title: "Delete", isDestructive: true) {
            isPresentingDeleteAlert = true
        }.alert(isPresented: $isPresentingDeleteAlert) {
            Alert(
                title: Text("Delete \(zimFile.name)"),
                message: Text("The zim file and all bookmarked articles linked to this zim file will be deleted."),
                primaryButton: .destructive(Text("Delete")) {
                    LibraryViewModel.delete(zimFileID: zimFile.fileID)
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    var downloadAction: some View {
        Action(title: "Download") {
            if let freeSpace = freeSpace, zimFile.size >= freeSpace - 10^9 {
                isPresentingDownloadAlert = true
            } else {
                Downloads.shared.start(zimFileID: zimFile.id, allowsCellularAccess: downloadUsingCellular)
            }
        }.alert(isPresented: $isPresentingDownloadAlert) {
            Alert(
                title: Text("Space Warning"),
                message: Text({
                    if let freeSpace = freeSpace, zimFile.size > freeSpace {
                        return "There might not be enough space on your device for this zim file."
                    } else {
                        return "There would be less than 1GB space left after the zim file is downloaded."
                    }
                }()),
                primaryButton: .default(Text("Download Anyway")) {
                    Downloads.shared.start(zimFileID: zimFile.id, allowsCellularAccess: false)
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    @ViewBuilder
    var basicInfo: some View {
        Attribute(title: "Language", detail: Locale.current.localizedString(forLanguageCode: zimFile.languageCode))
        Attribute(title: "Category", detail: Category(rawValue: zimFile.category)?.description)
        Attribute(title: "Size", detail: Formatter.size.string(fromByteCount: zimFile.size))
        Attribute(title: "Created", detail: Formatter.dateMedium.string(from: zimFile.created))
    }
    
    @ViewBuilder
    var boolInfo: some View {
        AttributeBool(title: "Pictures", detail: zimFile.hasPictures)
        AttributeBool(title: "Videos", detail: zimFile.hasVideos)
        AttributeBool(title: "Details", detail: zimFile.hasDetails)
        if zimFile.requiresServiceWorkers {
            AttributeBool(title: "Requires Service Workers", detail: zimFile.requiresServiceWorkers)
        }
    }
    
    @ViewBuilder
    var counts: some View {
        Attribute(
            title: "Article Count",
            detail: Formatter.number.string(from: NSNumber(value: zimFile.articleCount))
        )
        Attribute(
            title: "Media Count",
            detail: Formatter.number.string(from: NSNumber(value: zimFile.mediaCount))
        )
    }
    
    @ViewBuilder
    var id: some View {
        Attribute(title: "ID", detail: String(zimFile.fileID.uuidString.prefix(8)))
    }
    
    private var freeSpace: Int64? {
        try? FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            .volumeAvailableCapacityForImportantUsage
    }
}

private struct FileLocator: ViewModifier {
    @Binding var isPresenting: Bool
    
    func body(content: Content) -> some View {
        content.fileImporter(
            isPresented: $isPresenting,
            allowedContentTypes: [UTType(exportedAs: "org.openzim.zim")],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let url = urls.first else { return }
            LibraryOperations.open(url: url)
        }
    }
}

private struct DownloadTaskDetail: View {
    @ObservedObject var downloadTask: DownloadTask
    
    var body: some View {
        Action(title: "Cancel", isDestructive: true) {
            Downloads.shared.cancel(zimFileID: downloadTask.fileID)
        }
        if downloadTask.resumeData == nil {
            Action(title: "Pause") {
                Downloads.shared.pause(zimFileID: downloadTask.fileID)
            }
            Attribute(title: "Downloading...", detail: detail)
        } else {
            Action(title: "Resume") {
                Downloads.shared.resume(zimFileID: downloadTask.fileID)
            }
            Attribute(title: "Paused", detail: detail)
        }
        if let error = downloadTask.error {
            Text(error)
        }
    }
    
    var detail: String {
        if let percent = percent {
            return "\(size) - \(percent)"
        } else {
            return size
        }
    }
    
    var size: String {
        Formatter.size.string(fromByteCount: downloadTask.downloadedBytes)
    }
    
    var percent: String? {
        guard downloadTask.totalBytes > 0 else { return nil }
        let fractionCompleted = NSNumber(value: Double(downloadTask.downloadedBytes) / Double(downloadTask.totalBytes))
        return Formatter.percent.string(from: fractionCompleted)
    }
}

private struct Attribute: View {
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

private struct AttributeBool: View {
    let title: String
    let detail: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            #if os(macOS)
            Text(detail ? "Yes" : "No").foregroundColor(.secondary)
            #elseif os(iOS)
            if detail {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            } else {
                Image(systemName: "multiply.circle.fill").foregroundColor(.orange)
            }
            #endif
        }
    }
}

private struct Action: View {
    let title: String
    let isDestructive: Bool
    let alignment: HorizontalAlignment
    let action: (() -> Void)
    
    init(title: String,
         isDestructive: Bool = false,
         alignment: HorizontalAlignment = .center,
         action: @escaping (() -> Void) = {}
    ) {
        self.title = title
        self.isDestructive = isDestructive
        self.alignment = alignment
        self.action = action
    }
    
    var body: some View {
        Button(action: action, label: {
            HStack {
                if alignment != .leading { Spacer() }
                Text(title)
                    .fontWeight(.medium)
                    .foregroundColor(isDestructive ? .red : nil)
                if alignment != .trailing { Spacer() }
            }
        })
    }
}

private struct ServiceWorkerWarning: View {
    var body: some View {
        Label {
            Text("Zim files requiring service workers are not supported.")
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill").renderingMode(.original)
        }
    }
}

struct ZimFileDetail_Previews: PreviewProvider {
    static let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    static let zimFile: ZimFile = {
        let zimFile = ZimFile(context: context)
        zimFile.articleCount = 1000000
        zimFile.category = "wikipedia"
        zimFile.created = Date()
        zimFile.downloadURL = URL(string: "https://www.example.com")
        zimFile.fileID = UUID()
        zimFile.fileDescription = "A very long description"
        zimFile.flavor = "max"
        zimFile.hasDetails = true
        zimFile.hasPictures = false
        zimFile.hasVideos = true
        zimFile.languageCode = "en"
        zimFile.mediaCount = 100
        zimFile.name = "Wikipedia Zim File Name"
        zimFile.persistentID = ""
        zimFile.size = 1000000000
        return zimFile
    }()
    
    static var previews: some View {
        ZimFileDetail(url: .constant(nil), zimFile: zimFile).frame(width: 300).previewLayout(.sizeThatFits)
    }
}
