//
//  Library.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Library: View {
    #if os(macOS)
    @State var selectedTopic: LibraryTopic? = .opened
    let topics: [LibraryTopic] = [.opened, .downloads, .new]
    #elseif os(iOS)
    @SceneStorage("library.selectedTopic") private var selectedTopic: LibraryTopic = .opened
    let topics: [LibraryTopic] = [.opened, .categories, .downloads, .new]
    #endif
    
    @StateObject private var viewModel = LibraryViewModel()
    
    var body: some View {
        content
            .environmentObject(viewModel)
            .modifier(FileImporter(isPresented: $viewModel.isFileImporterPresented))
            .onAppear {
                Task {
                    try? await viewModel.refresh(isUserInitiated: false)
                }
            }
    }
    
    var content: some View {
        #if os(macOS)
        NavigationView {
            List(selection: $selectedTopic) {
                ForEach(topics, id: \.self) { topic in
                    Label(topic.name, systemImage: topic.iconName)
                }
                Section("Category") {
                    ForEach(Category.allCases.map{ LibraryTopic.category($0) }, id: \.self) { topic in
                        Text(topic.name)
                    }
                }.collapsible(false)
            }
            .frame(minWidth: 200)
            .toolbar { SidebarButton() }
            if let selectedTopic = selectedTopic {
                LibraryContent(topic: selectedTopic)
            }
        }
        #elseif os(iOS)
        TabView(selection: $selectedTopic) {
            ForEach(topics) { topic in
                SheetView {
                    LibraryContent(topic: topic)
                }
                .tag(topic)
                .tabItem { Label(topic.name, systemImage: topic.iconName) }
            }
        }
        #endif
    }
}

private struct LibraryContent: View {
    let topic: LibraryTopic
    
    var body: some View {
        switch topic {
        case .opened:
            ZimFilesOpened(isFileImporterPresented: .constant(false))
        case .downloads:
            ZimFilesDownloads()
        case .new:
            ZimFilesNew()
        case .categories:
            List(Category.allCases) { category in
                NavigationLink {
                    LibraryContent(topic: LibraryTopic.category(category))
                } label: {
                    HStack {
                        Favicon(category: category).frame(height: 26)
                        Text(category.name)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(LibraryTopic.categories.name)
        case .category(let category):
            if #available(iOS 15.0, *), category != .ted, category != .stackExchange, category != .other {
                ZimFilesGrid(category: category)
            } else {
                ZimFilesList(category: category)
            }
        }
    }
}
