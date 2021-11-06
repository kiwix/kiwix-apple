//
//  Sidebar.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 11/3/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct Sidebar: View {
    @Binding var displayMode: DisplayMode
    @State private var searchText: String = ""
    
    var body: some View {
        VStack {
            Divider()
            HStack(spacing: 20) {
                Button { displayMode = .search } label: {
                    Image(systemName: "magnifyingglass").foregroundColor(displayMode == .search ? .blue : nil)
                }.help("Search among on device zim files")
                Button { displayMode = .bookmark } label: {
                    Image(systemName: "star").foregroundColor(displayMode == .bookmark ? .blue : nil)
                }.help("Show sookmarked articles")
                Button { displayMode = .tableOfContent } label: {
                    Image(systemName: "list.bullet").foregroundColor(displayMode == .tableOfContent ? .blue : nil)
                }.help("Show table of content of current article")
                Button { displayMode = .library } label: {
                    Image(systemName: "folder").foregroundColor(displayMode == .library ? .blue : nil)
                }.help("Show library of zim files")
            }.padding(.vertical, -2.75).buttonStyle(.borderless).frame(maxWidth: .infinity)
            Divider()
            switch displayMode {
            case .search:
                SearchField(searchText: $searchText).padding(.horizontal, 6)
                Button("Scope") { }
                Divider()
                if !searchText.isEmpty {
                    List {
                        Text("result 1")
                        Text("result 2")
                        Text("result 3")
                    }
                } else {
                    List {}
                }
            case .bookmark:
                List {
                    Text("bookmarks")
                }
            case .tableOfContent:
                List {
                    Text("table of contents")
                }
            case .library:
                Library()
            }
        }
    }
    
    enum DisplayMode: String {
        case search, bookmark, tableOfContent, library
    }
}

extension FocusedValues {
    var sidebarDisplayMode: Binding<Sidebar.DisplayMode>? {
        get { self[SidebarDisplayModeKey.self] }
        set { self[SidebarDisplayModeKey.self] = newValue }
    }
    
    struct SidebarDisplayModeKey: FocusedValueKey {
        typealias Value = Binding<Sidebar.DisplayMode>
    }
}

private struct SearchField: NSViewRepresentable {
    @Binding var searchText: String
    
    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.delegate = context.coordinator
        return searchField
    }
    
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = searchText
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSSearchFieldDelegate {
        private var searchField: SearchField
        
        init(_ searchField: SearchField) {
            self.searchField = searchField
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let searchField = obj.object as? NSSearchField else { return }
            self.searchField.searchText = searchField.stringValue
        }
        func searchFieldDidEndSearching(_ sender: NSSearchField) {
            print(sender.stringValue)
        }
    }
}
