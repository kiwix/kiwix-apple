//
//  Library.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Library: View {
    @State var selectedTopic: Topic? = .opened
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        #if os(iOS)
        TabView(selection: $selectedTopic) {
            ForEach([Topic.opened, Topic.categories, Topic.downloads, Topic.new]) { topic in
                NavigationView {
                    topic.view
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
                .tabItem {
                    Image(systemName: topic.iconName)
                    Text(topic.name)
                }
            }
        }
        #elseif os(macOS)
        NavigationView {
            List(selection: $selectedTopic) {
                ForEach([Topic.opened, Topic.downloads, Topic.new], id: \.self) { topic in
                    Label(topic.name, systemImage: topic.iconName)
                }
                Section("Category") {
                    ForEach(Category.allCases.map{ Topic.category($0) }, id: \.self) { topic in
                        Text(topic.name)
                    }
                }.collapsible(false)
            }.navigationTitle("Library")
            Text("content")
        }
        #endif
    }
    
    enum Topic: Hashable, Identifiable {
        case opened, new, downloads, categories
        case category(Category)
        
        var id: String { name }
        
        var name: String {
            switch self {
            case .opened:
                return "Opened"
            case .new:
                return "New"
            case .downloads:
                return "Downloads"
            case .categories:
                return "Categories"
            case .category(let category):
                return category.description
            }
        }
        
        var iconName: String {
            switch self {
            case .opened:
                #if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    return "iphone"
                } else {
                    return "ipad"
                }
                #elseif os(macOS)
                return "laptopcomputer"
                #endif
            case .new:
                return "newspaper"
            case .downloads:
                return "tray.and.arrow.down"
            case .categories:
                return "books.vertical"
            case .category(_):
                return "book"
            }
        }
        
        @ViewBuilder
        var view: some View {
            switch self {
            case .opened:
                Text("Show opened zim files")
            case .new:
                Text("Show newly added zim files")
            case .downloads:
                Text("Show zim files being downloaded")
            case .categories:
                List {
                    ForEach(Category.allCases) { category in
                        NavigationLink {
                            Text("Show a specific category: \(category.description)")
                        } label: {
                            Text(category.description)
                        }
                    }
                }
            case .category(let category):
                Text("Show a specific category: \(category.description)")
            }
        }
    }
}

struct Library_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Library().previewDevice("iPhone 13 Pro")
            Library().previewDevice("iPad Pro (11-inch) (3rd generation)")
        }
    }
}
