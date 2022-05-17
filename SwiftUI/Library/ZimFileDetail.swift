//
//  ZimFileDetail.swift
//  Kiwix
//
//  Created by Chris Li on 4/30/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI

struct ZimFileDetail: View {
    @ObservedObject var zimFile: ZimFile
    @State var isUnlinkAlertPresented = false
    @State var isDeleteAlertPresented = false
    
    var body: some View {
        #if os(macOS)
        List {
            Section("Name") { Text(zimFile.name) }.collapsible(false)
            Section("Description") { Text(zimFile.fileDescription).lineLimit(nil) }.collapsible(false)
            if let downloadTask = zimFile.downloadTask {
                Section("Download") { DownloadTaskDetail(downloadTask: downloadTask) }.collapsible(false)
            } else if zimFile.fileURLBookmark != nil {
                Section("Actions") { actions }.collapsible(false)
            } else if zimFile.downloadURL != nil {
                Section("Download") {
                    Action(title: "Download") {
                        Downloads.shared.start(zimFileID: zimFile.id, allowsCellularAccess: false)
                    }
                }
            }
            Section("Info") {
                basicInfo
                boolInfo
                counts
                id
            }.collapsible(false)
        }
        .listStyle(.sidebar)
        .modifier(ZimFileUnlinkAlert(isPresented: $isUnlinkAlertPresented, zimFile: zimFile))
        #elseif os(iOS)
        List {
            Section {
                Text(zimFile.name)
                Text(zimFile.fileDescription).lineLimit(nil)
            }
            if let downloadTask = zimFile.downloadTask {
                Section { DownloadTaskDetail(downloadTask: downloadTask) }
            } else if zimFile.fileURLBookmark != nil {
                Section { actions }
            } else if zimFile.downloadURL != nil {
                Section {
                    Action(title: "Download") {
                        Downloads.shared.start(zimFileID: zimFile.id, allowsCellularAccess: false)
                    }
                }
            }
            Section { basicInfo }
            Section { boolInfo }
            Section { counts }
            Section { id }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(zimFile.name)
        .navigationBarTitleDisplayMode(.inline)
        .modifier(ZimFileDeleteAlert(isPresented: $isDeleteAlertPresented, zimFile: zimFile))
        .modifier(ZimFileUnlinkAlert(isPresented: $isUnlinkAlertPresented, zimFile: zimFile))
        #endif
    }
    
    @ViewBuilder
    var actions: some View {
        Action(title: "Open Main Page") {
            
        }
        #if os(macOS)
        Action(title: "Reveal in Finder") {
            guard let url = ZimFileService.shared.getFileURL(zimFileID: zimFile.id) else { return }
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
        #elseif os(iOS)
        Action(title: "Reveal in Files") {
            
        }
        #endif
        Action(title: "Unlink", isDestructive: true) {
            isUnlinkAlertPresented = true
        }
    }
    
    @ViewBuilder
    var basicInfo: some View {
        Attribute(title: "Language", detail: Locale.current.localizedString(forLanguageCode: zimFile.languageCode))
        Attribute(title: "Category", detail: Category(rawValue: zimFile.category)?.description)
        Attribute(title: "Size", detail: Library.sizeFormatter.string(fromByteCount: zimFile.size))
        Attribute(title: "Created", detail: Library.dateFormatterMedium.string(from: zimFile.created))
    }
    
    @ViewBuilder
    var boolInfo: some View {
        AttributeBool(title: "Pictures", detail: zimFile.hasPictures)
        AttributeBool(title: "Videos", detail: zimFile.hasVideos)
        AttributeBool(title: "Details", detail: zimFile.hasDetails)
    }
    
    @ViewBuilder
    var counts: some View {
        Attribute(
            title: "Article Count",
            detail: Library.numberFormatter.string(from: NSNumber(value: zimFile.articleCount))
        )
        Attribute(
            title: "Media Count",
            detail: Library.numberFormatter.string(from: NSNumber(value: zimFile.mediaCount))
        )
    }
    
    @ViewBuilder
    var id: some View {
        Attribute(title: "ID", detail: String(zimFile.fileID.uuidString.prefix(8)))
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
        Library.sizeFormatter.string(fromByteCount: downloadTask.downloadedBytes)
    }
    
    var percent: String? {
        guard downloadTask.totalBytes > 0 else { return nil }
        let fractionCompleted = NSNumber(value: Double(downloadTask.downloadedBytes) / Double(downloadTask.totalBytes))
        return Library.percentFormatter.string(from: fractionCompleted)
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
                Image(systemName: "multiply.circle.fill").foregroundColor(.secondary)
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
        ZimFileDetail(zimFile: zimFile).frame(width: 300).previewLayout(.sizeThatFits)
    }
}
