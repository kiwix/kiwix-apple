//
//  SearchBar.swift
//  Kiwix
//
//  Created by Chris Li on 8/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

@available(macOS 12.0, iOS 16.0, *)
struct SearchBar: UIViewRepresentable {
    @Binding var isSearchActive: Bool
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search"
        return searchBar
    }
    
    func updateUIView(_ searchBar: UISearchBar, context: Context) {
        if !isSearchActive {
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISearchBar, context: Context) -> CGSize? {
        guard let width = proposal.width, let height = proposal.height else { return nil }
        context.coordinator.proposedWidths.insert(width)
        let proposedWidth = isSearchActive ?
            context.coordinator.proposedWidths.min() :
            context.coordinator.proposedWidths.max()
        return CGSize(width: proposedWidth ?? width, height: height)
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        let view: SearchBar
        var proposedWidths = Set<CGFloat>()
        
        init(_ view: SearchBar) {
            self.view = view
        }
        
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            view.isSearchActive = true
        }
    }
}
