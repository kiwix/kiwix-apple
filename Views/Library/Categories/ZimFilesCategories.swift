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

import Defaults

/// A grid of zim files under each category.
struct ZimFilesCategories: View {
    @State private var selected: Category
    @Binding private var languageCode: String
    @Default(.hasSeenCategories) private var hasSeenCategories
    private var categories: [Category]
    private let dismiss: (() -> Void)?

    init(
        languageCode selectedLangCode: Binding<String>,
        dismiss: (() -> Void)?
    ) {
        _languageCode = selectedLangCode
        let categories = CategoriesToLanguages().categoriesIn(languageCode: selectedLangCode.wrappedValue)
        let selectedCategory: Category? = {
            guard let selectedCategoryId = Defaults[.selectedCategory] else {
                return nil
            }
            return categories.first { category in
                category.id == selectedCategoryId
            }
        }()
        self.categories = categories
        selected = selectedCategory ?? categories.first ?? .wikipedia
        self.dismiss = dismiss
    }

    var body: some View {
        ZimFilesCategory(category: $selected, selectedLanguage: $languageCode, dismiss: dismiss)
            .modifier(ToolbarRoleBrowser())
            .navigationTitle(MenuItem.categories.name)
            .toolbar {
                ToolbarItem(id: "picker", placement: .principal) {
                    Picker(LocalString.zim_file_category_title, selection: $selected) {
                        ForEach(categories) {
                            Text($0.name).tag($0)
                                .accessibilityIdentifier($0.name)
                        }
                    }
                }
            }.onAppear {
                Task {
                    await LibraryViewModel().start(isUserInitiated: false)
                }
            }
            .onDisappear {
                hasSeenCategories = true
                Defaults[.selectedCategory] = selected.id
            }
    }
}

/// A grid of zim files under a single category, or as a search result
struct ZimFilesCategory: View {
    @State private var searchText = ""
    @Binding var category: Category
    @Binding var selectedLanguage: String
    @Default(.libraryLanguageCodes) private var languageCodes
    @EnvironmentObject private var selection: SelectedZimFileViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest private var results: FetchedResults<ZimFile>
    let dismiss: (() -> Void)? // iOS only
    
    init(
        category: Binding<Category>,
        selectedLanguage: Binding<String>,
        dismiss: (() -> Void)?
    ) {
        self._category = category
        self._selectedLanguage = selectedLanguage
        self._results = FetchRequest<ZimFile>(
            sortDescriptors: [SortDescriptor(\ZimFile.name), SortDescriptor(\.size, order: .reverse)],
            predicate: ZimFilesCategory.buildPredicate(
                category: category.wrappedValue,
                searchText: "",
                languageCode: selectedLanguage.wrappedValue
            ),
            animation: .easeInOut
        )
        self.dismiss = dismiss
    }

    var body: some View {
        Group {
            if results.isEmpty {
                CategoryEmptySection()
            } else {
                LazyVGrid(columns: ([Self.gridItem]), alignment: .leading, spacing: 12) {
                    ForEach(results, id: \.fileID) { zimFile in
                        LibraryZimFileContext(
                            content: { ZimFileCell(
                                zimFile,
                                prominent: .name,
                                isSelected: selection.isSelected(zimFile)
                            )},
                            zimFile: zimFile,
                            selection: selection,
                            dismiss: dismiss)
                    }
                }.modifier(GridCommon())
            }
        }
        .searchable(text: $searchText, prompt: LocalString.common_search)
        .onChange(of: category) { selection.reset() }
        .onChange(of: searchText) { _, newValue in
            results.nsPredicate = ZimFilesCategory
                .buildPredicate(category: category, searchText: newValue, languageCode: selectedLanguage)
        }
        .onChange(of: selectedLanguage) {
            results.nsPredicate = ZimFilesCategory
                .buildPredicate(category: category, searchText: searchText, languageCode: selectedLanguage)
        }
        .onChange(of: languageCodes) {
            if !languageCodes.contains(selectedLanguage) {
                selectedLanguage = languageCodes.first ?? "eng"
            }
        }
    }
    
    private static let gridItem = GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)

    @MainActor
    static func buildPredicate(
        category: Category,
        searchText: String,
        languageCode: String
    ) -> NSPredicate {
        let regex = String(format: "(.*,)?%@(,.*)?", languageCode)
        let langPredicate = NSPredicate(format: "languageCode MATCHES %@", regex)
        var predicates: [NSPredicate] = []
        if searchText.isEmpty {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }
        predicates.append(langPredicate)
        predicates.append(NSPredicate(format: "requiresServiceWorkers == false"))
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
