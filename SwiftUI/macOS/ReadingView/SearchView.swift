//
//  SearchView.swift
//  Kiwix
//
//  Created by Chris Li on 8/19/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct SearchView: View {
    @Binding var url: URL?
    @Binding var searchText: String
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject var viewModel: SearchViewModel
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
        
        #endif
    }
    
    @ViewBuilder
    var content: some View {
        if zimFiles.isEmpty {
            Message(text: "No opened zim files")
        } else if searchText.isEmpty {
            List {
                recentSearch
                filter
            }
        } else if viewModel.inProgress {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.results.isEmpty {
            Message(text: "No result")
        } else {
            results
        }
    }
    
    var recentSearch: some View {
        Section {
            #if os(macOS)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                ForEach(1..<13) { index in
                    Button("recent search item \(index)") {
                        
                    }
                }
            }
            #elseif os(iOS)
            ForEach(1..<6) { index in
                Button("recent search item \(index)") {
                    
                }
            }
            #endif
        } header: { Text("Recent Search") }
    }
    
    var filter: some View {
        Section {
            ForEach(zimFiles) { zimFile in
                Toggle(zimFile.name, isOn: Binding<Bool>(get: {
                    zimFile.includedInSearch
                }, set: {
                    zimFile.includedInSearch = $0
                    try? managedObjectContext.save()
                }))
            }
        } header: { Text("Included in Search") }
    }
    
    var results: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(minimum: 300, maximum: 700), alignment: .center)]) {
                ForEach(viewModel.results) { result in
                    Button {
                        url = result.url
                    } label: {
                        ArticleCell(result: result, zimFile: viewModel.zimFiles[result.zimFileID])
                    }.buttonStyle(.plain)
                }
            }
            .padding()
        }.background(Color.background)
    }
}
