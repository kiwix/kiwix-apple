//
//  LibraryPrimaryView.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import RealmSwift

/// A list of all on device & downloading zim files and all zim file categories.
@available(iOS 14.0, *)
struct LibraryPrimaryView: View {
    @ObservedResults(
        ZimFile.self,
        configuration: Realm.defaultConfig,
        filter: NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
        sortDescriptor: SortDescriptor(keyPath: "creationDate", ascending: true)
    ) var onDevice
    @ObservedResults(
        ZimFile.self,
        configuration: Realm.defaultConfig,
        filter: NSPredicate(
            format: "stateRaw IN %@",
            [ZimFile.State.downloadQueued, .downloadInProgress, .downloadPaused, .downloadError].map({ $0.rawValue })
        ),
        sortDescriptor: SortDescriptor(keyPath: "creationDate", ascending: true)
    ) var download
    var zimFileSelected: (String, String) -> Void = { _, _ in }
    var categorySelected: (ZimFile.Category) -> Void = { _ in }
    
    var body: some View {
        List {
            if onDevice.count > 0 {
                Section(header: Text("On Device")) {
                    ForEach(onDevice) { zimFile in
                        Button(action: { zimFileSelected(zimFile.fileID, zimFile.title) }, label: {
                            ZimFileCell(zimFile)
                        })
                    }
                }
            }
            if download.count > 0 {
                Section(header: Text("Downloads")) {
                    ForEach(download) { zimFile in
                        Button(action: { zimFileSelected(zimFile.fileID, zimFile.title) }, label: {
                            HStack {
                                Favicon(data: zimFile.faviconData)
                                VStack(alignment: .leading) {
                                    Text(zimFile.title).lineLimit(1)
                                    Text([
                                        zimFile.downloadedSizeDescription, zimFile.downloadedPercentDescription
                                    ].compactMap({ $0 }).joined(separator: " - ")).lineLimit(1).font(.footnote)
                                }.foregroundColor(.primary)
                                Spacer()
                                DisclosureIndicator()
                            }
                        })
                    }
                }
            }
            Section(header: Text("Categories")) {
                ForEach(ZimFile.Category.allCases) { category in
                    Button(action: { categorySelected(category) }, label: {
                        HStack {
                            Favicon(uiImage: category.icon)
                            Text(category.description).foregroundColor(.primary)
                            Spacer()
                            DisclosureIndicator()
                        }
                    })
                }
            }
        }.listStyle(GroupedListStyle())
    }
}
