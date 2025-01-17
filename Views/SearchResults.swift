// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import SwiftUI

import Defaults

struct SearchResults: View {
    @Default(.recentSearchTexts) private var recentSearchTexts
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var viewModel: SearchViewModel
    @EnvironmentObject private var navigation: NavigationViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.Predicate.isDownloaded,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @FocusState.Binding var searchFocus: Int?

    private let openURL = NotificationCenter.default.publisher(for: .openURL)

    var body: some View {
        Group {
            if zimFiles.isEmpty {
                Message(text: "search_result.zimfile.empty.message".localized)
            } else if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    #if os(macOS)
                    sidebar.frame(width: 250)
                    #elseif os(iOS)
                    sidebar.frame(width: 350)
                    #endif
                    Divider().ignoresSafeArea(.all, edges: .vertical)
                    content.frame(maxWidth: .infinity)
                }.safeAreaInset(edge: .top, spacing: 0) {
                    Divider()
                }
            } else if viewModel.searchText.isEmpty {
                sidebar
            } else {
                content
            }
        }
        .background(Color.background)
        .onReceive(openURL) { _ in
            dismissSearch()
        }
    }

    @ViewBuilder
    var content: some View {
        if viewModel.inProgress {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                Spacer()
            }
        } else if viewModel.results.isEmpty {
            Message(text: "search_result.zimfile.no_result.message".localized)
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(minimum: 300, maximum: 700), alignment: .center)]) {
                    ForEach(viewModel.results) { result in
                        SearchResultButton(searchFocus: $searchFocus,
                                           searchText: viewModel.searchText,
                                           result: result,
                                           zimFile: viewModel.zimFiles[result.zimFileID])
                    }
                }.padding()
                    .onMoveCommand { direction in
                        let results = viewModel.results
                        if let searchFocus = self.searchFocus,
                           let index = results.firstIndex(where: {searchFocus == $0.id}) {
                            if direction == .up,
                               index > results.startIndex {
                                let prev = results.index(before: index)
                                self.searchFocus = results[prev].id
                            } else if direction == .down,
                                      index < results.endIndex {
                                let prev = results.index(after: index)
                                self.searchFocus = results[prev].id
                            }
                        } else {
                            self.searchFocus = results.first?.id
                        }
                    }
            }
        }
    }
    
    private static var openSearchResult: (_ result: SearchResult, _ searchText: String) -> Void
    = { result, searchText in
        var searchTexts = Defaults[.recentSearchTexts]
        searchTexts.removeAll(where: { $0 == searchText })
        searchTexts.insert(searchText, at: 0)
        Defaults[.recentSearchTexts] = searchTexts
        
        NotificationCenter.openURL(result.url)
    }

    private struct SearchResultButton: View {
        @FocusState.Binding var searchFocus: Int?
        var searchText: String
        var result: SearchResult
        var zimFile: ZimFile?
        
        var body: some View {
            
            if #available(macOS 14.0, iOS 17.0, *) {
                SearchResultButtonBase(searchText: searchText, result: result, zimFile: zimFile)
                    .focusable()
                    .focused($searchFocus, equals: result.id)
                    .onKeyPress(.return) {
                        openSearchResult(result, searchText)
                        return .handled
                    }
            } else {
                SearchResultButtonBase(searchText: searchText, result: result, zimFile: zimFile)
            }
                
        }
    }

    private struct SearchResultButtonBase: View {
        var searchText: String
        var result: SearchResult
        var zimFile: ZimFile?

        var body: some View {
            Button {
                openSearchResult(result, searchText)
            } label: {
                ArticleCell(result: result, zimFile: zimFile)
            } .buttonStyle(.plain)
        }
    }

    var sidebar: some View {
        List {
            if !recentSearchTexts.isEmpty {
                Section {
                    ForEach(recentSearchTexts.prefix(6), id: \.self) { searchText in
                        Button(searchText) {
                            viewModel.searchText = searchText
                        }.swipeActions {
                            Button("search_result.sidebar.button.remove".localized, role: .destructive) {
                                recentSearchTexts.removeAll { $0 == searchText }
                            }
                        }
                        #if os(macOS)
                        .buttonStyle(.link)
                        #endif
                    }
                } header: { recentSearchHeader }
            }
            if FeatureFlags.hasLibrary {
                Section {
                    ForEach(zimFiles) { zimFile in
                        HStack {
                            Toggle(zimFile.name, isOn: Binding<Bool>(get: {
                                zimFile.includedInSearch
                            }, set: {
                                zimFile.includedInSearch = $0
                                try? managedObjectContext.save()
                            }))
                            Spacer()
                        }
                    }
                } header: { searchFilterHeader }
            }
        }
    }

    private var recentSearchHeader: some View {
        HStack {
            Text("search_result.header.text".localized)
            Spacer()
            Button {
                recentSearchTexts.removeAll()
            } label: {
                Text("search_result.button.clear".localized).font(.caption).fontWeight(.medium)
            }
        }
    }

    private var searchFilterHeader: some View {
        HStack {
            Text("search_result.filter_hearder.text".localized)
            Spacer()
            if zimFiles.count == zimFiles.filter({ $0.includedInSearch }).count {
                Button {
                    zimFiles.forEach { $0.includedInSearch = false }
                    try? managedObjectContext.save()
                } label: {
                    Text("search_result.filter_hearder.button.none".localized).font(.caption).fontWeight(.medium)
                }
            } else {
                Button {
                    zimFiles.forEach { $0.includedInSearch = true }
                    try? managedObjectContext.save()
                } label: {
                    Text("search_result.filter_hearder.button.all".localized).font(.caption).fontWeight(.medium)
                }
            }
        }
    }
}
