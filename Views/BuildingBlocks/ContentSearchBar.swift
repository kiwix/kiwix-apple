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

    @State private var isActivated: Bool = false
    @FocusState private var focusedState: Bool

    init(text: Binding<String>) {
        _searchText = text
    }

    var body: some View {
        if isActivated {
            field
                .focused($focusedState)
        } else {
            button
                .keyboardShortcut("f")
        }
    }

    private var button: some View {
        Button {
            isActivated = true
            focusedState = true
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(32)
    }

    private var field: some View {
        HStack {
            searchImage
            TextField("common.search".localized, text: $searchText)
                .textFieldStyle(.roundedBorder)
            closeButton
        }
        .padding(8)
        .background(Color.background)
        .padding(16)
        .cornerRadius(16)
        .frame(maxWidth: 320)
    }

    private var searchImage: some View {
        Image(systemName: "magnifyingglass")
            .foregroundColor(.primary)
    }

    private var closeButton: some View {
        Button {
            searchText = ""
            isActivated = false
        } label: {
            Image(systemName: "xmark.circle.fill").foregroundColor(.primary)
        }
    }

}
