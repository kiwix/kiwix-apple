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
            VStack(spacing: 20) {
                Text("No zim files").font(.title)
                Text("Add some zim files to start a search.").font(.title2).foregroundColor(.secondary)
            }.padding()
        } else if horizontalSizeClass == .regular {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ZStack(alignment: .trailing) {
                        filter
                        Divider()
                    }.frame(width: max(340, geometry.size.width * 0.35))
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
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = geometry.size.width > 400 ? 20 : 16
            ScrollView {
                LazyVStack {
                    SectionHeader(text: "Recent Search").padding(.horizontal, horizontalPadding)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            ForEach(searchViewModel.recentSearchTexts, id: \.hash) { searchText in
                                RecentSearchButton(text: searchText)
                            }
                        }.padding(.horizontal, horizontalPadding)
                    }
                    .padding(.top, -4)
                    .padding(.bottom, 8)
                    SectionHeader(text: "Search Filter").padding(.horizontal, horizontalPadding)
                    ForEach(zimFilesViewModel.onDevice, id: \.id) { zimFile in
                        ZimFileCell(zimFile, withIncludedInSearchIcon: true) {
                            zimFilesViewModel.toggleIncludedInSearch(zimFileID: zimFile.id)
                        }
                    }.padding(.horizontal, horizontalPadding)
                }.padding(.vertical, 16)
            }
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
    
    private var noSearchText: some View {
        VStack(spacing: 12) {
            Text("No Search Results")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text("Please enter some text to start a search.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity)
    }
    
    private var noResult: some View {
        VStack(spacing: 12) {
            Text("No Search Results")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text("Please update the search text or search filter.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }.padding().frame(maxWidth: .infinity)
    }
    
    private var results: some View {
        List(searchViewModel.results, id: \.hashValue) { result in
            Button {
                sceneViewModel.load(url: result.url)
                searchViewModel.cancelSearch()
                searchViewModel.updateRecentSearchText()
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
fileprivate struct SectionHeader : View {
    let text: String
    
    var body: some View {
        HStack {
            Text(text).font(.body).fontWeight(.semibold)
            Spacer()
        }
    }
}

@available(iOS 14.0, *)
fileprivate struct RecentSearchButton : View {
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
