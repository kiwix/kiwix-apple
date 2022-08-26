//
//  SearchView.swift
//  Kiwix
//
//  Created by Chris Li on 8/19/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

struct SearchView: View {
    @Binding var url: URL?
    @Default(.recentSearchTexts) private var recentSearchTexts
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var viewModel: SearchViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.withFileURLBookmarkPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        #if os(macOS)
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                Color.clear
                content
                    .background(Material.thin)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )
                    .frame(width: min(proxy.size.width * 0.75, 425), height: min(proxy.size.height * 0.8, 600))
                    .padding(8)
            }
        }
        #elseif os(iOS)
        Group {
            if zimFiles.isEmpty {
                Message(text: "No opened zim file")
            } else if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    noSearchText.frame(width: 320)
                    Divider().ignoresSafeArea(.all, edges: .bottom)
                    content.frame(maxWidth: .infinity)
                }
            } else {
                content
            }
        }.background(Color.background)
        #endif
    }
    
    @ViewBuilder
    var content: some View {
        if zimFiles.isEmpty {
            Message(text: "No opened zim file")
        } else if viewModel.searchText.isEmpty, horizontalSizeClass == .compact {
            noSearchText
        } else if viewModel.inProgress {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.results.isEmpty {
            Message(text: "No result")
        } else {
            results
        }
    }
    
    var filter: some View {
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
    }
    
    var noSearchText: some View {
        #if os(macOS)
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible())]) {
                if !recentSearchTexts.isEmpty {
                    Section {
                        ForEach(recentSearchTexts.prefix(12), id: \.self) { searchText in
                            Button {
                                DispatchQueue.main.async {
                                    viewModel.searchText = searchText
                                }
                            } label: {
                                RecentSearch(searchText: searchText)
                            }.buttonStyle(.borderless)
                        }
                    } header: {
                        HStack {
                            Text("Recent Search").fontWeight(.medium)
                            Spacer()
                        }
                    }
                }
                Spacer().frame(height: 20)
                Section {
                    filter
                } header: {
                    HStack {
                        Text("Included in Search").fontWeight(.medium)
                        Spacer()
                    }
                }
            }.padding()
        }
        #elseif os(iOS)
        List {
            if !recentSearchTexts.isEmpty {
                Section {
                    ForEach(recentSearchTexts.prefix(6), id: \.self) { searchText in
                        Button(searchText) {
                            DispatchQueue.main.async {
                                viewModel.searchText = searchText
                            }
                        }
                    }
                } header: { Text("Recent Search") }
            }
            Section {
                filter
            } header: { Text("Included in Search") }
        }
        #endif
    }
    
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
                        url = result.url
                    } label: {
                        ArticleCell(result: result, zimFile: viewModel.zimFiles[result.zimFileID])
                    }.buttonStyle(.plain)
                }
            }.padding()
        }.background(Color.background)
    }
}

struct RecentSearch: View {
    @State var isHovering: Bool = false
    
    let searchText: String
    
    var body: some View {
        HStack {
            Text(searchText).font(.headline).foregroundColor(.primary)
            Spacer()
        }
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        .modifier(CellBackground(isHovering: isHovering))
        .onHover { self.isHovering = $0 }
    }
}
