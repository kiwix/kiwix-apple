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
    @EnvironmentObject var sceneViewModel: SceneViewModel
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
                        searchFilter
                        Divider()
                    }
                    .frame(width: max(340, geometry.size.width * 0.35))
                    List{
                        Text(sceneViewModel.searchText)
                    }
                }
            }
            
        } else {
            searchFilter
        }
    }
    
    var searchFilter: some View {
        LazyVStack {
            Section(header: HStack {
                Text("Search Filter").font(.title3).fontWeight(.semibold)
                Spacer()
            }.padding(.leading, 10)) {
                ForEach(zimFilesViewModel.onDeviceZimFiles, id: \.id) { zimFile in
                    ZimFileCell(zimFile) {
//                        sceneViewModel.loadMainPage(zimFile: zimFile)
                    }
                }
            }
        }
        .modifier(ScrollableModifier())
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}
