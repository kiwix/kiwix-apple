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

import Foundation
import SwiftUI

struct ContentSearchBar: View {

    @Binding private var searchText: String

    init(text: Binding<String>) {
        _searchText = text
    }

    var body: some View {
        searchBar
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.primary)
            TextField("common.search".localized, text: $searchText)
                .textFieldStyle(.roundedBorder)
        }
        .padding(8)
        .background(Color.background)
        .cornerRadius(16)
        .padding(16)
        .frame(maxWidth: 320)
    }
}
