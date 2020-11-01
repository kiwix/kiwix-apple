//
//  SearchView.swift
//  Kiwix
//
//  Created by Chris Li on 10/25/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct SearchView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var zimFilesViewModel: ZimFilesViewModel
    
    var body: some View {
        if zimFilesViewModel.onDeviceZimFiles.isEmpty {
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
                    if searchViewModel.isInProgress {
                        Text("In Progress")
                    } else if searchViewModel.searchText.isEmpty {
                        noSearchText
                    } else if searchViewModel.results.isEmpty {
                        noResult
                    } else {
                        results
                    }
                }
            }
        } else {
            if searchViewModel.isInProgress {
                Text("In Progress")
            } else if searchViewModel.searchText.isEmpty {
                filter
            } else if searchViewModel.results.isEmpty {
                noResult
            } else {
                results
            }
        }
    }
    
    private var filter: some View {
        LazyVStack {
            Section(header: HStack {
                Text("Search Filter").font(.title3).fontWeight(.semibold)
                Spacer()
            }.padding(.leading, 10)) {
                ForEach(zimFilesViewModel.onDeviceZimFiles, id: \.id) { zimFile in
                    ZimFileCell(zimFile, withIncludedInSearchIcon: true) {
                        zimFilesViewModel.toggleIncludedInSearch(zimFileID: zimFile.id)
                    }
                }
            }
        }
        .modifier(ScrollableModifier())
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
    
    private var noSearchText: some View {
        VStack(spacing: 12) {
            Text("No Search Results").font(.title).fontWeight(.semibold).foregroundColor(.primary)
            Text("Please enter some text to start a search.").font(.title3).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity)
    }
    
    private var noResult: some View {
        VStack(spacing: 12) {
            Text("No Search Results").font(.title).fontWeight(.semibold).foregroundColor(.primary)
            Text("Please update the search text or search filter.").font(.title3).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity)
    }
    
    private var results: some View {
        List{
            ForEach(searchViewModel.results, id: \.hashValue) { result in
                Text(result.title)
            }
        }
    }
}
