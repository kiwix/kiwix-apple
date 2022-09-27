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
    @Binding var isActive: Bool
    @Default(.recentSearchTexts) private var recentSearchTexts
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var viewModel: SearchViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.withFileURLBookmarkPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isPresentingClearRecentSearchConfirmation = false
    
    // dismissSearch is in a separate section because it is only needed in macOS,
    // only available for macOS 12 / iOS 15, and this view has to work for iOS 14 as well
    #if os(macOS)
    @Environment(\.dismissSearch) private var dismissSearch
    #endif
    
    var body: some View {
        #if os(macOS)
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                Color.black.opacity(0.001).onTapGesture { dismissSearch() }
                content
                    .background(Material.regular)
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
        }
        .background(Color.background.ignoresSafeArea())
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
    
    var recentSearches: some View {
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
            }
        } header: {
            HStack {
                Text("Recent Search")
                Spacer()
                Button {
                    isPresentingClearRecentSearchConfirmation = true
                } label: {
                    Text("Clear").font(.caption).fontWeight(.medium)
                }.alert(isPresented: $isPresentingClearRecentSearchConfirmation) {
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
    }
    
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
    
    var noSearchText: some View {
        List {
            if !recentSearchTexts.isEmpty {
                recentSearches
            }
            filter
        }
        #if os(iOS)
        .listStyle(.insetGrouped) // explicit list style required for iOS 14
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
                        isActive = false
                        #if os(macOS)
                        dismissSearch()
                        #endif
                    } label: {
                        ArticleCell(result: result, zimFile: viewModel.zimFiles[result.zimFileID])
                    }.buttonStyle(.plain)
                }
            }.padding()
        }
    }
}
