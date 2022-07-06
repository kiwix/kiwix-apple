//
//  Search.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 7/6/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Search: View {
    @Binding var url: URL?
    @StateObject var viewModel = SearchViewModel()
    @FocusState var focused: SearchFocusState?
    
    var body: some View {
        VStack {
            TextField("Search", text: $viewModel.searchText)
                .onSubmit {
                    focused = .content
                    url = viewModel.results.first?.url
                }
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 8)
                .focused($focused, equals: .searchField)
                
            List(viewModel.results, id: \.url, selection: $url) { result in
                Text(result.title)
            }.focused($focused, equals: .content)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { SearchFilter().frame(height: 200) }
        .focusedSceneValue(\.searchFieldFocusAction) { focused = .searchField }
        .onAppear { focused = .searchField }
    }
    
    enum SearchFocusState: Hashable {
      case searchField, content
    }
}
