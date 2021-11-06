//
//  Search.swift
//  macOS_SwiftUI
//
//  Created by Chris Li on 11/6/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct Search: View {
    @State private var searchText: String = ""
    
    var body: some View {
        SearchField(searchText: $searchText).padding(.horizontal, 6)
        Button("Scope") { }
        Divider()
        List {
            if searchText.isEmpty {
                EmptyView()
            } else {
                Text("result 1")
                Text("result 2")
                Text("result 3")
            }
        }
    }
}

private class ViewModel: ObservableObject {
    private let queue = OperationQueue()
    
    
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
    }
}
