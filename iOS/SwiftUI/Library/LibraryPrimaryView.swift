//
//  LibraryPrimaryView.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import Defaults
import RealmSwift

/// A list of all on device & downloading zim files and all zim file categories.
@available(iOS 13.0, *)
struct LibraryPrimaryView: View {
    @Default(.libraryLastRefresh) private var libraryLastRefresh
    @ObservedResults(
        ZimFile.self,
        configuration: Realm.defaultConfig,
        filter: NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
        sortDescriptor: SortDescriptor(keyPath: "size", ascending: false)
    ) private var onDevice
    @ObservedResults(
        ZimFile.self,
        configuration: Realm.defaultConfig,
        filter: NSPredicate(
            format: "stateRaw IN %@",
            [ZimFile.State.downloadQueued, .downloadInProgress, .downloadPaused, .downloadError].map({ $0.rawValue })
        ),
        sortDescriptor: SortDescriptor(keyPath: "size", ascending: false)
    ) private var download
    @ObservedObject private var viewModel = ViewModel()
    var zimFileSelected: (String, String) -> Void = { _, _ in }
    var categorySelected: (ZimFile.Category) -> Void = { _ in }
    
    var body: some View {
        List {
            if onDevice.count == 0, libraryLastRefresh == nil {
                Section(header: Text("Get Started")) {
                    ActionCell(
                        title: viewModel.isRefreshing ? "Refreshing..." : "Download Online Catalog",
                        alignment: .leading
                    ) { viewModel.refresh() }.disabled(viewModel.isRefreshing)
                }
            }
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
                                    ZimFileDownloadDetailView(zimFile).lineLimit(1).font(.footnote)
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
    
    class ViewModel: ObservableObject {
        @Published private(set) var isRefreshing = false
        
        init() {
            if let operation = LibraryOperationQueue.shared.currentOPDSRefreshOperation {
                isRefreshing = !operation.isFinished
            }
        }
        
        func refresh() {
            guard LibraryOperationQueue.shared.currentOPDSRefreshOperation == nil else { return }
            LibraryOperationQueue.shared.addOperation(OPDSRefreshOperation())
            isRefreshing = true
        }
    }
}
