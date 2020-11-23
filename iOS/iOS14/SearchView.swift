//
//  SearchView.swift
//  Kiwix
//
//  Created by Chris Li on 10/25/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import Defaults
import RealmSwift

@available(iOS 14.0, *)
struct SearchView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var sceneViewModel: SceneViewModel
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var zimFilesViewModel: ZimFilesViewModel
    
    var body: some View {
        if zimFilesViewModel.onDevice.isEmpty {
            Message(
                title: "No zim Files",
                detail: "Add some zim files to start a search."
            )
        } else if horizontalSizeClass == .regular {
            HStack(spacing: 0) {
                ZStack(alignment: .trailing) {
                    filter
                    Divider()
                }.frame(width: 320)
                switch searchViewModel.content {
                case .initial:
                    noSearchText
                case .inProgress:
                    inProgress
                case .results:
                    results
                case .noResult:
                    noResult
                }
            }
        } else {
            switch searchViewModel.content {
            case .initial:
                filter
            case .inProgress:
                inProgress
            case .results:
                results
            case .noResult:
                noResult
            }
        }
    }
    
    private var filter: some View {
        List {
            Section(header: Text("Recent Search")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach(searchViewModel.recentSearchTexts, id: \.hash) { searchText in
                            RecentSearchButton(text: searchText)
                        }
                    }.padding(.horizontal, 20)
                }.listRowInsets(EdgeInsets())
            }
            Section(header: Text("Search Filter")) {
                ForEach(zimFilesViewModel.onDevice, id: \.id) { zimFile in
                    Button {
                        zimFilesViewModel.toggleIncludedInSearch(zimFileID: zimFile.id)
                    } label: {
                        HStack(alignment: .center, spacing: 8) {
                            Favicon(zimFile: zimFile)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(zimFile.title).font(.subheadline).fontWeight(.semibold).lineLimit(1)
                                Text(zimFile.description).font(.caption).lineLimit(1)
                            }.foregroundColor(.primary)
                            Spacer()
                            if zimFile.includedInSearch {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            }
                        }.animation(Animation.easeInOut(duration: 0.1))
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }
    
    private var noSearchText: some View {
        Message(
            title: "No Search Results",
            detail: "Please enter some text to start a search."
        )
    }
    
    private var noResult: some View {
        Message(
            title: "No Search Results",
            detail: "Please update the search text or search filter."
        )
    }
    
    private var results: some View {
        List(searchViewModel.results, id: \.hashValue) { result in
            Button {
                sceneViewModel.load(url: result.url)
                searchViewModel.updateRecentSearchText()
                searchViewModel.cancelSearch()
            } label: {
                HStack(alignment: result.snippet == nil ? .center : .top) {
                    Favicon(zimFile: zimFilesViewModel.onDevice.first(where: {$0.id == result.zimFileID}))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.title).font(.headline).lineLimit(1)
                        if let snippet = result.snippet {
                            Text(snippet.string).font(.footnote).lineLimit(4)
                        }
                    }
                }
            }
        }
    }
    
    private var inProgress: some View {
        List(0..<10) { _ in
            HStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(.secondarySystemFill))
                VStack(alignment: .leading) {
                    Text(String(repeating: "Title", count: 4)).font(.headline).lineLimit(1)
                    Text(String(repeating: "Snippet", count: 40)).font(.footnote).lineLimit(4)
                }
            }
        }
        .redacted(reason: .placeholder)
        .disabled(true)
    }
}

@available(iOS 14.0, *)
private struct RecentSearchButton : View {
    @EnvironmentObject var searchViewModel: SearchViewModel
    let text: String
    
    var body: some View {
        Button  {
            searchViewModel.searchBar.text = text
            searchViewModel.rawSearchText = text
        } label: {
            Text(text)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(Color(.white))
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

@available(iOS 14.0, *)
private struct Message : View {
    let title: String
    let detail: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text(detail)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
