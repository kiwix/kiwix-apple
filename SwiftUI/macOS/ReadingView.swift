//
//  ReadingView.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct ReadingView: View {
    @Binding var url: URL?
    @Environment(\.isSearching) private var isSearching
    @State var searchText = ""
    
    var body: some View {
        WebView(url: $url)
            .ignoresSafeArea(edges: .all)
            .overlay(alignment: .top) {
                if isSearching {
                    List {
                        Text("result 1")
                        Text("result 2")
                        Text("result 3")
                    }
                } else if url == nil {
                    Welcome(url: $url)
                }
            }
    }
}
