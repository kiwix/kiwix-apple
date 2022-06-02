//
//  Search.swift
//  Kiwix
//
//  Created by Chris Li on 5/30/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

#if os(macOS)
struct Search: View {
    @StateObject var viewModel = SearchViewModel()
    
    var body: some View {
        ZStack {
            List {}.searchable(text: $viewModel.searchText, placement: .sidebar, prompt: Text("Search"))
            if !viewModel.results.isEmpty {
                List(viewModel.results) { result in
                    Text(result.title)
                }.padding(.top, 34)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            SearchFilter().frame(height: 200)
        }
    }
}
#elseif os(iOS)
struct Search: View {
    @Binding var searchText: String
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .regular {
            HStack(spacing: 0) {
                SearchFilter().listStyle(.grouped).frame(width: 320)
                Divider().ignoresSafeArea(.container, edges: .bottom)
                List {
                    Text("result 1")
                    Text("result 2")
                    Text("result 3")
                }
                .listStyle(.plain)
            }
        } else if searchText.isEmpty {
            SearchFilter()
        } else {
            List {
                Text("result 1")
                Text("result 2")
                Text("result 3")
            }
        }
    }
}
#endif
