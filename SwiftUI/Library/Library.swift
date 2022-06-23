//
//  Library.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

#if os(macOS)
struct Library: View {
    @State var selectedTopic: LibraryTopic? = .opened
    @StateObject private var viewModel = LibraryViewModel()
    
    let topics: [LibraryTopic] = [.opened, .downloads, .new]
    
    var body: some View {
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
        }.task {
            try? await viewModel.refresh(isUserInitiated: false)
        }
    }
}
#elseif os(iOS)
struct Library: View {
    @Environment(\.presentationMode) private var presentationMode
    @SceneStorage("library.selectedTopic") private var selectedTopic: LibraryTopic = .opened
    @StateObject private var viewModel = LibraryViewModel()
    
    let topics: [LibraryTopic] = [.opened, .categories, .downloads, .new]
    
    var body: some View {
        TabView(selection: $selectedTopic) {
            ForEach(topics) { topic in
                NavigationView {
                    LibraryContent(topic: topic)
                        .navigationTitle(topic.name)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                }
                .navigationViewStyle(.stack)
                .tag(topic)
                .tabItem { Label(topic.name, systemImage: topic.iconName) }
            }
        }
        .environmentObject(viewModel)
        .onAppear {
            Task {
                try? await viewModel.refresh(isUserInitiated: false)
            }
        }
    }
}
#endif
