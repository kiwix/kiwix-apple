//
//  LibraryZimFileDetail.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 1/1/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct LibraryZimFileDetail: View {
    @Binding var zimFile: ZimFile?
    
    var body: some View {
        if let zimFile = zimFile {
            List {
                Section("Name") {
                    Text(zimFile.name).font(.callout)
                }
                Section("Description") {
                    Text("To be, or not to be: that is the question: whether 'tis nobler in the mind to suffer the slings and arrows of outrageous fortune, or to take arms against a sea of troubles, and by opposing end them?").lineLimit(nil).font(.callout)
                }
                Section("Attributes") {
                    Attribute(title: "Language",
                              detail: Locale.current.localizedString(forIdentifier: zimFile.languageCode) ?? "Unknown")
                    Attribute(title: "Category", detail: (Category(rawValue: zimFile.category) ?? .other).description)
                    Attribute(title: "Size", detail: zimFile.size.formatted(.byteCount(style: .file)))
                    Attribute(title: "Date", detail: zimFile.created.formatted(date: .abbreviated, time: .omitted))
                    Attribute(title: "Article", detail: zimFile.articleCount.formatted(.number.notation(.compactName)))
                    Attribute(title: "Media", detail: zimFile.mediaCount.formatted(.number.notation(.compactName)))
                    Attribute(title: "ID", detail: zimFile.fileID.uuidString)
                }
            }.listStyle(.automatic)
        } else {
            Text("Select a zim file to see detail")
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
}

private struct Attribute: View {
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack {
                Spacer(minLength: 0)
                Text("\(title):")
            }.frame(width: 60)
            Text(detail).lineLimit(nil)
        }.font(.callout)
    }
}

struct LibraryZimFileDetail_Previews: PreviewProvider {
    static let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    static let zimFile: ZimFile = {
        let zimFile = ZimFile(context: context)
        zimFile.articleCount = 100
        zimFile.category = "wikipedia"
        zimFile.created = Date()
        zimFile.fileID = UUID()
        zimFile.languageCode = "en"
        zimFile.mediaCount = 100
        zimFile.name = "Wikipedia Zim File Name"
        zimFile.persistentID = ""
        zimFile.size = 1000000000
        zimFile.tag = "max"
        return zimFile
    }()
    
    static var previews: some View {
        LibraryZimFileDetail(zimFile: .constant(nil)).frame(width: 250)
        LibraryZimFileDetail(zimFile: .constant(zimFile)).frame(width: 250, height: 500)
    }
}
