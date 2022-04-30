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
    @Binding var zimFile: ZimFile?
    
    var body: some View {
        if let zimFile = zimFile {
            #if os(macOS)
            List {
                HStack {
                    if #available(iOS 15.0, *) {
                        Favicon(
                            category: Category(rawValue: zimFile.category) ?? .other,
                            imageData: zimFile.faviconData,
                            imageURL: zimFile.faviconURL
                        ).frame(height: 26)
                    }
                    Spacer()
                    Button("Download") {
                        
                    }
                }
                Section("Name & Description") {
                    Text(zimFile.name)
                    Text(zimFile.fileDescription)
                }
                Section("Info") {
                    ZimFileDetailRow(
                        title: "Language",
                        detail: Locale.current.localizedString(forLanguageCode: zimFile.languageCode)
                    )
                    ZimFileDetailRow(
                        title: "Category",
                        detail: Category(rawValue: zimFile.category)?.description
                    )
                    ZimFileDetailRow(
                        title: "Size",
                        detail: Library.sizeFormatter.string(fromByteCount: zimFile.size)
                    )
                    ZimFileDetailRow(
                        title: "Created",
                        detail: Library.dateFormatterMedium.string(from: zimFile.created)
                    )
                    ZimFileDetailRowBool(title: "Has Pictures", detail: zimFile.hasPictures)
                    ZimFileDetailRowBool(title: "Has Videos", detail: zimFile.hasVideos)
                    ZimFileDetailRowBool(title: "Has Details", detail: zimFile.hasDetails)
                    ZimFileDetailRow(title: "Article Count", detail: zimFile.articleCount.formatted())
                    ZimFileDetailRow(title: "Media Count", detail: zimFile.mediaCount.formatted())
                    ZimFileDetailRow(title: "ID", detail: String(zimFile.fileID.uuidString.prefix(8)))
                }
            }
            #elseif os(iOS)
            List {
                Section {
                    Text(zimFile.name)
                    Text(zimFile.fileDescription)
                }
                Section {
                    ZimFileAction(title: "Download")
                }
                Section {
                    ZimFileAttribute(
                        title: "Language",
                        detail: Locale.current.localizedString(forLanguageCode: zimFile.languageCode)
                    )
                    ZimFileAttribute(
                        title: "Category",
                        detail: Category(rawValue: zimFile.category)?.description
                    )
                    ZimFileAttribute(
                        title: "Size",
                        detail: Library.sizeFormatter.string(fromByteCount: zimFile.size)
                    )
                    ZimFileAttribute(
                        title: "Created",
                        detail: Library.dateFormatterMedium.string(from: zimFile.created)
                    )
                }
                Section {
                    ZimFileDetailRowBool(title: "Has Pictures", detail: zimFile.hasPictures)
                    ZimFileDetailRowBool(title: "Has Videos", detail: zimFile.hasVideos)
                    ZimFileDetailRowBool(title: "Has Details", detail: zimFile.hasDetails)
                }
                Section {
                    ZimFileAttribute(
                        title: "Article Count",
                        detail: Library.numberFormatter.string(from: NSNumber(value: zimFile.articleCount))
                    )
                    ZimFileAttribute(
                        title: "Media Count",
                        detail: Library.numberFormatter.string(from: NSNumber(value: zimFile.mediaCount))
                    )
                }
                ZimFileAttribute(title: "ID", detail: String(zimFile.fileID.uuidString.prefix(8)))
            }
            .listStyle(.insetGrouped)
            .navigationTitle(zimFile.name)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        } else {
            Text("Select a zim file to view details")
        }
    }
}

private struct ZimFileAttribute: View {
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

private struct ZimFileAction: View {
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

private struct ZimFileDetailRowBool: View {
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

struct ZimFileDetail_Previews: PreviewProvider {
    static let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    static let zimFile: ZimFile = {
        let zimFile = ZimFile(context: context)
        zimFile.articleCount = 1000000
        zimFile.category = "wikipedia"
        zimFile.created = Date()
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
        ZimFileDetail(zimFile: .constant(nil)).padding().previewLayout(.sizeThatFits)
        ZimFileDetail(zimFile: .constant(zimFile)).frame(width: 300).previewLayout(.sizeThatFits)
    }
}
