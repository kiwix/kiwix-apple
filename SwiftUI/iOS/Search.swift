//
//  Search.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 7/6/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

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
        }
        .onChange(of: searchText) { searchText in
            viewModel.searchText = searchText
        }
    }
    
    var splitView: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                SearchFilter().frame(width: min(320, proxy.size.width * 0.35))
                Divider().ignoresSafeArea(.container, edges: .bottom)
                if searchText.isEmpty {
                    Message(text: "Enter some text to start searching")
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
                    if proxy.size.width > 1000 {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible(minimum: 300, maximum: 700), alignment: .center)]) {
                                ForEach(viewModel.results) { result in
                                    Button {
                                        UIApplication.shared.open(result.url)
                                    } label: {
                                        ArticleCell(result: result, zimFile: viewModel.zimFiles[result.zimFileID])
                                    }
                                }
                            }.padding()
                        }.frame(maxWidth: .infinity)
                    } else {
                        List(viewModel.results) { result in
                            Button {
                                UIApplication.shared.open(result.url)
                            } label: {
                                SearchResultRow(result: result, zimFile: viewModel.zimFiles[result.zimFileID])
                            }
                        }.listStyle(.plain)
                    }
                } else {
                    Message(text: "No results")
                }
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
                    UIApplication.shared.open(result.url)
                } label: {
                    SearchResultRow(result: result, zimFile: viewModel.zimFiles[result.zimFileID])
                }
            }.listStyle(.plain)
        } else {
            Message(text: "No results")
        }
    }
}
