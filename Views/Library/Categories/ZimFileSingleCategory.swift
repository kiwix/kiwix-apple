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

struct ZimFileSingleCategory: View {
    @State private var searchText: String
    @State private var categoryBy: CategoryBy
    private let category: Category
    @Binding private var selectedLanguage: String
    @Binding private var libraryLanguageCodes: [String]
    @EnvironmentObject private var selection: SelectedZimFileViewModel
    private let dismiss: (() -> Void)? // iOS only
    
    init(
        category: Category,
        selectedLanguage: Binding<String>,
        libraryLanguageCodes: Binding<[String]>,
        dimiss: (@MainActor @Sendable () -> Void)?
    ) {
        self.category = category
        // initially start with the listing from the category
        self.categoryBy = CategoryBy.category(category)
        self.searchText = ""
        self._selectedLanguage = selectedLanguage
        self._libraryLanguageCodes = libraryLanguageCodes
        self.dismiss = dimiss
    }
    
    var body: some View {
        ZimFilesCategoryResult(
            categoryBy: categoryBy,
            selectedLanguage: $selectedLanguage,
            dismiss: self.dismiss
        )
        .navigationTitle(categoryBy.navTitle())
        .searchable(
            text: $searchText,
            placement: SearchFieldPlacement.inNavBarDrawer(),
            prompt: LocalString.common_search
        )
        .onChange(of: searchText) { oldValue, newValue in
            guard oldValue != newValue else { return }
            selection.reset() // reset the selected ZIM file in the side panel on macOS
            if newValue.isEmpty {
                categoryBy = CategoryBy.category(category)
            } else {
                categoryBy = CategoryBy.search(newValue)
            }
        }
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.forLanguageButton()) {
                ToggleAroundLanguageButton(items: $libraryLanguageCodes, selection: $selectedLanguage)
                    .disabled($libraryLanguageCodes.count <= 1)
            }
        }
    }
}
