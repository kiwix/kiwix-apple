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
    @Binding var url: URL?
    @StateObject var viewModel = SearchViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            List {}.searchable(text: $viewModel.searchText, placement: .sidebar, prompt: Text("Search"))
            Group {
                if viewModel.results.isEmpty, !viewModel.searchText.isEmpty, !viewModel.inProgress {
                    Message(text: "No results")
                } else {
                    List(viewModel.results, id: \.url, selection: $url) { result in
                        Text(result.title)
                    }
                }
            }.padding(.top, 34)
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
    @StateObject var viewModel = SearchViewModel()
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                splitView
            } else {
                stackView
            }
        }.onChange(of: searchText) { searchText in
            viewModel.searchText = searchText
        }
    }
    
    var splitView: some View {
        HStack(spacing: 0) {
            SearchFilter().frame(width: 320)
            Divider().ignoresSafeArea(.container, edges: .bottom)
            if searchText.isEmpty {
                Message(text: "Enter some text to search for articles")
            } else if viewModel.inProgress {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        ProgressView("Searching…")
                        Spacer()
                    }
                    Spacer()
                }
            } else if !viewModel.results.isEmpty {
                List(viewModel.results) { result in
                    Button {
                        
                    } label: {
                        Text(result.title)
                    }
                }.listStyle(.plain)
            } else {
                Message(text: "No results")
            }
        }
    }
    
    @ViewBuilder
    var stackView: some View {
        if searchText.isEmpty {
            SearchFilter()
        } else if viewModel.inProgress {
            ProgressView("Searching…")
        } else if !viewModel.results.isEmpty {
            List(viewModel.results) { result in
                Button {
                    
                } label: {
                    Text(result.title)
                }
            }.listStyle(.plain)
        } else {
            Message(text: "No results")
        }
    }
}
#endif
