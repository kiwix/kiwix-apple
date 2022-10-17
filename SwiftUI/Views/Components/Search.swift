//
//  Search.swift
//  Kiwix
//
//  Created by Chris Li on 8/19/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

struct Search: View {
    @Default(.recentSearchTexts) private var recentSearchTexts
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var viewModel: SearchViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.withFileURLBookmarkPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    
    let onSelection: (SearchResult) -> Void
    
    var body: some View {
        Group {
            if zimFiles.isEmpty {
                Message(text: "No opened zim file")
            } else if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    sidebar.frame(width: 320)
                    Divider().ignoresSafeArea(.all, edges: .vertical)
                    content.frame(maxWidth: .infinity)
                }
            } else {
                content
            }
        }
    }
    
    @ViewBuilder
    var content: some View {
        if zimFiles.isEmpty {
            Message(text: "No opened zim file")
        } else if viewModel.searchText.isEmpty, horizontalSizeClass == .compact {
            sidebar
        } else if viewModel.inProgress {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.results.isEmpty {
            Message(text: "No result")
        } else {
            results
        }
    }
    
    /// A list with recent searches and search filter sections.
    /// - Note: Upon activating search, this is the first thing user see on compact interfaces, or displayed on the side on regular interfaces.
    var sidebar: some View {
        List {
            if !recentSearchTexts.isEmpty { recent }
            filter
        }
        #if os(iOS)
        .listStyle(.insetGrouped) // explicit list style required for iOS 14
        #endif
    }
    
    /// Recently executed search terms.
    var recent: some View {
        Section {
            ForEach(recentSearchTexts.prefix(6), id: \.self) { searchText in
                Button(searchText) {
                    DispatchQueue.main.async {
                        viewModel.searchText = searchText
                    }
                }.modify { button in
                    if #available(iOS 15.0, *) {
                        button.swipeActions {
                            Button("Remove", role: .destructive) {
                                recentSearchTexts.removeAll { $0 == searchText }
                            }
                        }
                    } else {
                        button
                    }
                }
                #if os(macOS)
                .buttonStyle(.link)
                #endif
            }
        } header: {
            HStack {
                Text("Recent Search")
                Spacer()
                ClearRecentSearchButton()
            }
        }
    }
    
    /// View and select zim files included in scope of search.
    var filter: some View {
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
        } header: {
            HStack(alignment: .firstTextBaseline) {
                Text("Included in Search").fontWeight(.medium)
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
    
    /// Search results, based on the search text and scope.
    var results: some View {
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
                        onSelection(result)
                    } label: {
                        ArticleCell(result: result, zimFile: viewModel.zimFiles[result.zimFileID])
                    }.buttonStyle(.plain)
                }
            }.padding()
        }
    }
}

private struct ClearRecentSearchButton: View {
    @Default(.recentSearchTexts) private var recentSearchTexts
    @State private var isPresentingConfirmation = false
    
    var body: some View {
        Button {
            isPresentingConfirmation = true
        } label: {
            Text("Clear").font(.caption).fontWeight(.medium)
        }.alert(isPresented: $isPresentingConfirmation) {
            Alert(
                title: Text("Recent Searches"),
                message: Text("Clear recent search history. This action is not recoverable."),
                primaryButton: .destructive(Text("Clear")) {
                    withAnimation {
                        recentSearchTexts.removeAll()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}
