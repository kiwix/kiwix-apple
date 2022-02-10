//
//  SearchField.swift
//  macOS_SwiftUI
//
//  Created by Chris Li on 11/27/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct SearchField: NSViewRepresentable {
    @Binding var searchText: String
    @State var isFocused: Bool = false
    
    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.delegate = context.coordinator
        return searchField
    }
    
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = searchText
        if isFocused {
            nsView.becomeFirstResponder()
        } else {
            nsView.resignFirstResponder()
        }
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
