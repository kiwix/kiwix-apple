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

#if os(iOS)
import SwiftUI
import CoreData

struct CompactView: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @Environment(\.dismissSearch) private var dismissSearch
    @StateObject var searchViewModel = SearchViewModel()
    private let openURL = NotificationCenter.default.publisher(for: .openURL)
    
    var body: some View {
        if case .loading = navigation.currentItem {
            LoadingDataView()
                .task { [weak navigation] in
                    navigation?.observeOpeningFiles()
                }
        } else if case let .tab(tabID) = navigation.currentItem {
            NavigationStack {
                SearchableContent(viewModel: searchViewModel, tabID: tabID)
                    .searchable(
                        text: $searchViewModel.searchText,
                        placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: LocalString.common_search
                    )
            }
            .onReceive(openURL) { _ in
                dismissSearch()
            }
        }
    }
}

private struct SearchableContent: View {
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.isSearching) private var isSearching
    let tabID: NSManagedObjectID
    
    var body: some View {
        CompactTabView(tabID: tabID)
            .overlay {
                if isSearching {
                    SearchResults(viewModel: viewModel)
                }
            }
    }
}

#endif
