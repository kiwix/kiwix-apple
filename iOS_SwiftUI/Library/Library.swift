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
                .tabItem {
                    Image(systemName: topic.iconName)
                    Text(topic.name)
                }
            }
        }.onAppear {
            Task {
                try? await Database.shared.refreshZimFileCatalog()
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
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
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
        
        var predicate: NSPredicate {
            var predicates = [NSPredicate(format: "languageCode == %@", "en")]
            switch self {
            case .category(let category):
                predicates.append(NSPredicate(format: "category == %@", category.rawValue))
            default:
                break
            }
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
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
