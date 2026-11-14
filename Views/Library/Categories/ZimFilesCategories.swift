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

import CoreData
import Defaults
import SwiftUI

///// A grid of zim files under each category.

//struct ZimFilesCategories: View {
//    @State private var searchText = ""
//    @State private var selected: Category
//    @State private var selectedLanguage: String
//    @Default(.libraryLanguageCodes) private var languages
//    @Default(.hasSeenCategories) private var hasSeenCategories
//    private var categories: [Category]
//    
//    init() {
//        let selectedLanguage = Defaults[.libraryLanguageCodes].first ?? "eng"
//        let categories = CategoriesToLanguages().categoriesIn(languageCode: selectedLanguage)
//        self.selectedLanguage = selectedLanguage
//        let selectedCategory: Category? = {
//            guard let selectedCategoryId = Defaults[.selectedCategory] else {
//                return nil
//            }
//            return categories.first { category in
//                category.id == selectedCategoryId
//            }
//        }()
//        self.categories = categories
//        selected = selectedCategory ?? categories.first ?? .wikipedia
//    }
//    
//    var body: some View {
//        ZimFilesCategory(
//            category: $selected,
//            searchText: $searchText,
//            selectedLanguage: $selectedLanguage,
//            dismiss: nil
//        )
//        .modifier(ToolbarRoleBrowser())
//        .navigationTitle(MenuItem.explore.name)
//        .searchable(text: $searchText, prompt: LocalString.common_search)
//        .toolbar {
//            ToolbarItem(id: "picker", placement: .principal) {
//                if searchText.isEmpty {
//                    Picker(LocalString.zim_file_category_title, selection: $selected) {
//                        ForEach(categories) {
//                            Text($0.name).tag($0)
//                                .accessibilityIdentifier($0.name)
//                        }
//                    }
//                }
//            }
//            #if os(iOS)
//                ToolbarItem(placement: .topBarTrailing) {
//                    ToggleAroundLanguageButton(items: $languages, selection: $selectedLanguage)
//                        .disabled(languages.count <= 1)
//                }
//            #else
//                if $languages.count > 1 {
//                    ToolbarItem(placement: .secondaryAction) {
//                        ToggleAroundLanguageButton(items: $languages, selection: $selectedLanguage)
//                    }
//                }
//            #endif
//        }.onAppear {
//            Task {
//                await LibraryViewModel().start(isUserInitiated: false)
//            }
//        }
//        .onDisappear {
//            hasSeenCategories = true
//            Defaults[.selectedCategory] = selected.id
//        }
//        .onChange(of: languages) { (_, new: [String]) in
//            if !new.contains(selectedLanguage) {
//                selectedLanguage = new.first ?? "eng"
//            }
//        }
//    }
//}


struct ZimFileSingleCategory: View {
    @State private var searchText: String
    @State private var categoryBy: CategoryBy
    private let category: Category
    @Binding private var selectedLanguage: String
    @State private var libraryLanguageCodes: [String]
    private let dismiss: (() -> Void)? // iOS only
    
    init(
        category: Category,
        selectedLanguage: Binding<String>,
        libraryLanguageCodes: [String],
        dimiss: (@MainActor @Sendable ()-> Void)?
    ) {
        self.category = category
        // initially start with the listing from the category
        self.categoryBy = CategoryBy.category(category)
        self.searchText = ""
        self._selectedLanguage = selectedLanguage
        self.libraryLanguageCodes = libraryLanguageCodes
        self.dismiss = dimiss
    }
    
    var body: some View {
        ZimFilesCategoryResult(
            categoryBy: categoryBy,
            selectedLanguage: $selectedLanguage,
            dismiss: self.dismiss
        )
        .navigationTitle(categoryBy.navTitle())
        .searchable(text: $searchText, prompt: LocalString.common_search)
        .onChange(of: searchText) { oldValue, newValue in
            guard oldValue != newValue else { return }
            if newValue.isEmpty {
                categoryBy = CategoryBy.category(category)
            } else {
                categoryBy = CategoryBy.search(newValue)
            }
        }
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                ToggleAroundLanguageButton(
                    items: $libraryLanguageCodes,
                    selection: $selectedLanguage
                )
                    .disabled($libraryLanguageCodes.count <= 1)
            }
#else
            if $languages.count > 1 {
                ToolbarItem(placement: .secondaryAction) {
                    ToggleAroundLanguageButton(
                        items: $libraryLanguageCodes,
                        selection: $selectedLanguage
                    )
                }
            }
#endif
        }
    }
}


/// A grid of zim files under a single category as a result, or as a search result in the same format
struct ZimFilesCategoryResult: View {
    @State var categoryBy: CategoryBy
    @Binding var selectedLanguage: String
    @Default(.libraryLanguageCodes) private var languageCodes
    @EnvironmentObject private var selection: SelectedZimFileViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest private var results: FetchedResults<ZimFile>
    let dismiss: (() -> Void)? // iOS only
    
    init(
        categoryBy: CategoryBy,
        selectedLanguage: Binding<String>,
        dismiss: (() -> Void)?
    ) {
        self.categoryBy = categoryBy
        self._selectedLanguage = selectedLanguage
        self._results = FetchRequest<ZimFile>(
            sortDescriptors: [SortDescriptor(\ZimFile.name), SortDescriptor(\.size, order: .reverse)],
            predicate: ZimFilesCategoryResult.buildPredicate(
                by: categoryBy,
                languageCode: selectedLanguage.wrappedValue
            ),
            animation: .easeInOut
        )
        self.dismiss = dismiss
    }
    
    var body: some View {
        Group {
            if results.isEmpty {
                switch categoryBy {
                case .category:
                    CategoryEmptySection()
                case .search:
                    CateogoryNoResultSection()
                }
            } else {
                LazyVGrid(columns: ([Self.gridItem]), alignment: .leading, spacing: 12) {
                    ForEach(results, id: \.fileID) { zimFile in
                        LibraryZimFileContext(
                            content: { ZimFileCell(
                                zimFile,
                                isSelected: selection.isSelected(zimFile)
                            )},
                            zimFile: zimFile,
                            selection: selection,
                            dismiss: dismiss)
                    }
                }.modifier(GridCommon())
            }
        }
//        .navigationTitle(categoryBy.navTitle())
//        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: categoryBy) {
            selection.reset()
            results.nsPredicate = ZimFilesCategoryResult
                .buildPredicate(by: categoryBy, languageCode: selectedLanguage)
        }
        .onChange(of: selectedLanguage) {
            results.nsPredicate = ZimFilesCategoryResult
                .buildPredicate(by: categoryBy, languageCode: selectedLanguage)
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
        by categoryBy: CategoryBy,
        languageCode: String
    ) -> NSPredicate {
        let regex = String(format: "(.*,)?%@(,.*)?", languageCode)
        let langPredicate = NSPredicate(format: "languageCode MATCHES %@", regex)
        var predicates: [NSPredicate] = []
        predicates.append(ZimFile.Predicate.notDownloaded())
        predicates.append(langPredicate)
        predicates.append(NSPredicate(format: "requiresServiceWorkers == false"))
        switch categoryBy {
        case let .category(category):
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        case let .search(searchText):
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "name CONTAINS[cd] %@", searchText),
                NSPredicate(format: "fileDescription CONTAINS[cd] %@", searchText)
            ]))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

enum CategoryBy: Equatable {
    case category(Category)
    case search(String)
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (let .category(lhsCat), let .category(rhsCat)):
            return lhsCat == rhsCat
        case (let .search(lhsText), let .search(rhsText)):
            return lhsText == rhsText
        default:
            return false
        }
    }
    
    func navTitle() -> String {
        debugPrint("\(#function)")
        switch self {
        case .category(let category):
            return category.name
        case .search:
            return LocalString.search_result_header_text
        }
    }
}
