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
    @Environment(\.isSearching) private var isSearching
    @EnvironmentObject private var viewModel: SearchViewModel
    @EnvironmentObject private var navigation: NavigationViewModel
    @FocusState private var focusedSearchItem: String? // macOS only
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.Predicate.isDownloaded,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>

    var body: some View {
        Group {
#if os(macOS)
            // Special hidden button to enable down key response when
            // search is active, to go to search results
            if isSearching, focusedSearchItem == nil {
                Button(action: {
                    switch viewModel.results {
                    case let .results(results):
                        focusedSearchItem = results.first?.url.absoluteString
                    case let .suggestions(suggestions):
                        focusedSearchItem = suggestions.first
                    }
                }, label: {})
                .hidden()
                .keyboardShortcut(.downArrow, modifiers: [])
            }
#endif
            if zimFiles.isEmpty {
                Message(text: LocalString.search_result_zimfile_empty_message)
            } else if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
#if os(macOS)
                    sidebar.frame(width: 250)
#elseif os(iOS)
                    sidebar.frame(width: 350)
#endif
                    Divider().ignoresSafeArea(.all, edges: .vertical)
                    content.frame(maxWidth: .infinity)
                }
            } else if viewModel.searchText.isEmpty {
                sidebar
            } else {
                content
            }
        }
        .background(Color.background)
    }
    
    @ViewBuilder
    var content: some View {
        if case SearchResultItems.results([]) = viewModel.results {
            if viewModel.searchText.isEmpty {
                Spacer()
            } else { 
                Message(text: LocalString.search_result_zimfile_no_result_message)
            }
        } else {
            ScrollViewReader { scrollReader in
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(minimum: 300, maximum: 700), alignment: .center)]) {
                        
                        switch viewModel.results {
                        case let .results(results):
                            ForEach(results, id: \.url.absoluteString) { result in
                                Button {
                                    openResult(result: result)
                                } label: {
                                    ArticleCell(result: result, zimFile: viewModel.zimFiles[result.zimFileID])
                                }
                                .buttonStyle(.plain)
                                .modifier(
                                    Focusable( // macOS only
                                        $focusedSearchItem,
                                        equals: result.url.absoluteString,
                                        onReturn: {
                                            openResult(result: result)
                                        },
                                        onDismiss: {
                                            $focusedSearchItem.wrappedValue = nil
                                            dismissSearch()
                                        })
                                )
                            }
                        case let .suggestions(suggestions):
                            
                            Text(LocalString.common_search_suggestion)
                                .font(.callout)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                            
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button {
                                    viewModel.searchText = suggestion
                                } label: {
                                    ArticleCell(searchSuggestion: suggestion)
                                }
                                .buttonStyle(.plain)
                                .modifier(
                                    Focusable( // macOS only
                                        $focusedSearchItem,
                                        equals: suggestion,
                                        onReturn: {
                                            viewModel.searchText = suggestion
                                        },
                                        onDismiss: {
                                            $focusedSearchItem.wrappedValue = nil
                                            dismissSearch()
                                        })
                                )
                            }
                        }
                    }.padding()
                }
                .onReceive(self.focusedSearchItem.publisher) { focusedURL in
                    scrollReader.scrollTo(focusedURL, anchor: .center)
                }
                .modifier(MoveCommand(perform: { direction in
                    // macOS only
                    if let focusedSearchItem,
                       let index = viewModel.results.firstIndex(where: focusedSearchItem) {
                        let nextIndex: Int
                        switch direction {
                        case .up: nextIndex = viewModel.results.index(before: index)
                        case .down: nextIndex = viewModel.results.index(after: index)
                        default: nextIndex = viewModel.results.startIndex
                        }
                        if nextIndex < viewModel.results.startIndex {
                            $focusedSearchItem.wrappedValue = nil
#if os(macOS)
                            NotificationCenter.default.post(name: .zimSearch, object: nil)
#endif
                        } else if (viewModel.results.startIndex..<viewModel.results.endIndex).contains(nextIndex) {
                            switch viewModel.results {
                            case let .results(results):
                                $focusedSearchItem.wrappedValue = results[nextIndex].url.absoluteString
                            case let .suggestions(suggestions):
                                $focusedSearchItem.wrappedValue = suggestions[nextIndex]
                            }
                        }
                    }
                }))
                .overlay(alignment: .center) {
                    if viewModel.inProgress {
                        ProgressView()
                    }
                }
            }
        }
    }
    
    private func openResult(result: SearchResult) {
        recentSearchTexts = {
            var searchTexts = Defaults[.recentSearchTexts]
            searchTexts.removeAll(where: { $0 == viewModel.searchText })
            searchTexts.insert(viewModel.searchText, at: 0)
            return searchTexts
        }()

        dismissSearch()
        #if os(macOS)
        // delayed fix for placement: .toolbarPrincipal on macOS
        // as it's not always dismissing properly, so we try again if needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if isSearching {
                dismissSearch()
            }
        }
        #endif
        NotificationCenter.openURL(result.url)
    }

    var sidebar: some View {
        List {
            if !FeatureFlags.hasLibrary || !recentSearchTexts.isEmpty {
                Section {
                    ForEach(recentSearchTexts.prefix(6), id: \.self) { searchText in
                        Button(searchText) {
                            viewModel.searchText = searchText
                        }.swipeActions {
                            Button(LocalString.search_result_sidebar_button_remove, role: .destructive) {
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
                    ForEach(zimFiles, id: \.fileID) { zimFile in
                        HStack {
                            Toggle(zimFile.name, isOn: Binding<Bool>(get: {
                                zimFile.includedInSearch && !zimFile.isMissing
                            }, set: {
                                zimFile.includedInSearch = $0
                                try? managedObjectContext.save()
                            })).disabled(zimFile.isMissing)
                            Spacer()
                        }
                    }
                } header: { searchFilterHeader }
            }
        }
        .modifier(NotFocusable()) // macOS only
    }
    
    private var recentSearchHeader: some View {
        HStack {
            Text(LocalString.search_result_header_text)
            Spacer()
            Button {
                recentSearchTexts.removeAll()
            } label: {
                Text(LocalString.search_result_button_clear).font(.caption).fontWeight(.medium)
            }
            .disabled(recentSearchTexts.isEmpty)
        }
    }
    
    private var searchFilterHeader: some View {
        HStack {
            Text(LocalString.search_result_filter_hearder_text)
            Spacer()
            if zimFiles.count == zimFiles.filter({ $0.includedInSearch }).count {
                Button {
                    zimFiles.forEach { $0.includedInSearch = false }
                    try? managedObjectContext.save()
                } label: {
                    Text(LocalString.search_result_filter_hearder_button_none).font(.caption).fontWeight(.medium)
                }
            } else {
                Button {
                    zimFiles.forEach { $0.includedInSearch = true }
                    try? managedObjectContext.save()
                } label: {
                    Text(LocalString.search_result_filter_hearder_button_all).font(.caption).fontWeight(.medium)
                }
            }
        }
    }
}
