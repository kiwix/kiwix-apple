//
//  Search.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 11/6/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import CoreData
import SwiftUI

import Defaults

/// Search interface in the sidebar.
struct Search: View {
    @Binding var url: URL?
    @ObservedObject var viewModel: SearchViewModel
    @State private var selectedSearchText: String?
    @Default(.recentSearchTexts) private var recentSearchTexts: [String]
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.size, order: .reverse)],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var showingPopover = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                SearchField(searchText: $viewModel.searchText)
                Spacer()
                Button {
                    showingPopover = true
                } label: {
                    if Set(zimFiles.map { $0.fileID }) == Set(viewModel.zimFileIDs) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    } else {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(zimFiles.count == 0)
                .help("Filter search results by zim files")
                .foregroundColor(zimFiles.count > 0 ? .blue : .gray)
                .popover(isPresented: $showingPopover) {
                    SearchFilter().frame(width: 250, height: 200)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            if viewModel.searchText.isEmpty, !recentSearchTexts.isEmpty {
                List(selection: $selectedSearchText) {
                    Section("Recent Search") {
                        ForEach(recentSearchTexts, id: \.self) { searchText in
                            Text(searchText)
                        }
                    }
                }.onChange(of: selectedSearchText) { self.updateCurrentSearchText($0) }
            } else if !viewModel.searchText.isEmpty, !viewModel.results.isEmpty {
                List(viewModel.results, id: \.url, selection: $url) { searchResult in
                    Text(searchResult.title)
                }.onChange(of: url) { _ in self.updateRecentSearchTexts(viewModel.searchText) }
            } else if !viewModel.searchText.isEmpty, viewModel.results.isEmpty, !viewModel.inProgress {
                List { Text("No Result") }
            } else {
                List { }
            }
        }
    }
    
    private func updateCurrentSearchText(_ searchText: String?) {
        guard let searchText = searchText else { return }
        viewModel.searchText = searchText
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectedSearchText = nil
        }
    }
    
    private func updateRecentSearchTexts(_ searchText: String) {
        guard !searchText.isEmpty else { return }
        var recentSearchTexts = self.recentSearchTexts
        recentSearchTexts.removeAll { $0 == searchText }
        recentSearchTexts.insert(searchText, at: 0)
        self.recentSearchTexts = recentSearchTexts
    }
}

struct Search_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Search(url: .constant(nil), viewModel: SearchViewModel())
        }.frame(width: 250, height: 550).listStyle(.sidebar)
    }
}
