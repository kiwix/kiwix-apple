//
//  SearchResults.swift
//  Kiwix
//
//  Created by Chris Li on 8/19/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

struct SearchResults: View {
    @Default(.recentSearchTexts) private var recentSearchTexts
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var viewModel: SearchViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.withFileURLBookmarkPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isClearSearchConfirmationPresented = false
    
    var body: some View {
        Group {
            if zimFiles.isEmpty {
                Message(text: "No opened zim file")
            } else if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    sidebar.frame(width: 320)
                    Divider().ignoresSafeArea(.all, edges: .vertical)
                    content.frame(maxWidth: .infinity)
                }.safeAreaInset(edge: .top, spacing: 0) {
                    Divider()
                }
            } else if viewModel.searchText.isEmpty {
                sidebar
            } else {
                content
            }
        }.background(Color.background)
    }
    
    @ViewBuilder
    var content: some View {
        if viewModel.inProgress {
            ProgressView()
        } else if viewModel.results.isEmpty {
            Message(text: "No result")
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(minimum: 300, maximum: 700), alignment: .center)]) {
                    ForEach(viewModel.results) { result in
                        Button {
                            recentSearchTexts = {
                                var searchTexts = Defaults[.recentSearchTexts]
                                searchTexts.removeAll(where: { $0 == viewModel.searchText })
                                searchTexts.insert(viewModel.searchText, at: 0)
                                return searchTexts
                            }()
                            NotificationCenter.default.post(
                                name: Notification.Name.openURL, object: nil, userInfo: ["url": result.url]
                            )
                            dismissSearch()
                        } label: {
                            ArticleCell(result: result, zimFile: viewModel.zimFiles[result.zimFileID])
                        }.buttonStyle(.plain)
                    }
                }.padding()
            }
        }
    }
    
    var sidebar: some View {
        List {
            if !recentSearchTexts.isEmpty {
                Section {
                    ForEach(recentSearchTexts.prefix(6), id: \.self) { searchText in
                        Button(searchText) {
                            DispatchQueue.main.async {
                                viewModel.searchText = searchText
                            }
                        }.swipeActions {
                            Button("Remove", role: .destructive) {
                                recentSearchTexts.removeAll { $0 == searchText }
                            }
                        }
                        #if os(macOS)
                        .buttonStyle(.link)
                        #endif
                    }
                } header: { recentSearchHeader }
            }
            Section {
                ForEach(zimFiles) { zimFile in
                    HStack {
                        Toggle(zimFile.name, isOn: Binding<Bool>(get: {
                            zimFile.includedInSearch
                        }, set: {
                            zimFile.includedInSearch = $0
                            try? managedObjectContext.save()
                        }))
                        Spacer()
                    }
                }
            } header: { searchFilterHeader }
        }
    }
    
    private var recentSearchHeader: some View {
        HStack {
            Text("Recent Search")
            Spacer()
            Button {
                isClearSearchConfirmationPresented = true
            } label: {
                Text("Clear").font(.caption).fontWeight(.medium)
            }.confirmationDialog("Clear Recent Searches", isPresented: $isClearSearchConfirmationPresented) {
                Button("Clear All", role: .destructive) {
                    recentSearchTexts.removeAll()
                }
            } message: {
                Text("All recent search history will be removed.")
            }
        }
    }
    
    private var searchFilterHeader: some View {
        HStack {
            Text("Included in Search")
            Spacer()
            if zimFiles.count == zimFiles.filter({ $0.includedInSearch }).count {
                Button {
                    zimFiles.forEach { $0.includedInSearch = false }
                    try? managedObjectContext.save()
                } label: {
                    Text("None").font(.caption).fontWeight(.medium)
                }
            } else {
                Button {
                    zimFiles.forEach { $0.includedInSearch = true }
                    try? managedObjectContext.save()
                } label: {
                    Text("All").font(.caption).fontWeight(.medium)
                }
            }
        }
    }
}
