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
        ZimFilesCategory(category: $selected, languageCode: $languageCode, dismiss: dismiss)
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

/// A grid or list of zim files under a single category.
struct ZimFilesCategory: View {
    @Binding var category: Category
    @Binding var languageCode: String
    @State private var searchText = ""
    let dismiss: (() -> Void)? // iOS only

    var body: some View {
        if category == .ted || category == .stackExchange || category == .other {
            CategoryList(
                category: $category,
                selectedLanguage: $languageCode,
                searchText: $searchText,
                dismiss: dismiss
            )
        } else {
            CategoryGrid(
                category: $category,
                selectedLanguage: $languageCode,
                searchText: $searchText,
                dismiss: dismiss
            )
        }
    }

    @MainActor
    static func buildPredicate(
        category: Category,
        searchText: String,
        languageCode: String
    ) -> NSPredicate {
        let regex = String(format: "(.*,)?%@(,.*)?", languageCode)
        let langPredicate = NSPredicate(format: "languageCode MATCHES %@", regex)
        var predicates = [
            NSPredicate(format: "category == %@", category.rawValue),
            langPredicate,
            NSPredicate(format: "requiresServiceWorkers == false")
        ]
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

private struct CategoryGrid: View {
    @Binding var category: Category
    @Binding var selectedLanguage: String
    @Binding var searchText: String
    @Default(.libraryLanguageCodes) private var languageCodes
    @EnvironmentObject private var selection: SelectedZimFileViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @SectionedFetchRequest private var sections: SectionedFetchResults<String, ZimFile>
    private let dismiss: (() -> Void)? // iOS only

    init(
        category: Binding<Category>,
        selectedLanguage: Binding<String>,
        searchText: Binding<String>,
        dismiss: (() -> Void)?
    ) {
        self._selectedLanguage = selectedLanguage
        self._category = category
        self._searchText = searchText
        self.dismiss = dismiss
        self._sections = SectionedFetchRequest<String, ZimFile>(
            sectionIdentifier: \.name,
            sortDescriptors: [SortDescriptor(\ZimFile.name), SortDescriptor(\.size, order: .reverse)],
            predicate: ZimFilesCategory.buildPredicate(
                category: category.wrappedValue,
                searchText: searchText.wrappedValue,
                languageCode: selectedLanguage.wrappedValue
            ),
            animation: .easeInOut
        )
    }

    var body: some View {
        Group {
            if sections.isEmpty {
                CategoryEmptySection()
            } else {
                LazyVGrid(columns: ([gridItem]), alignment: .leading, spacing: 12) {
                    ForEach(sections) { section in
                        Section {
                            ForEach(section, id: \.fileID) { zimFile in
                                LibraryZimFileContext(
                                    content: { ZimFileCell(
                                        zimFile,
                                        prominent: .size,
                                        isSelected: selection.isSelected(zimFile)
                                    )
                                    },
                                    zimFile: zimFile,
                                    selection: selection,
                                    dismiss: dismiss)
                            }
                        } header: {
                            SectionHeader(
                                title: section.id,
                                category: Category(rawValue: section.first?.category) ?? .other,
                                imageData: section.first?.faviconData,
                                imageURL: section.first?.faviconURL
                            ).padding(
                                EdgeInsets(
                                    top: section.id == sections.first?.id ? 0 : 10,
                                    leading: 12,
                                    bottom: -6,
                                    trailing: 0
                                )
                            )
                        }
                    }
                }.modifier(GridCommon())
            }
        }
        .searchable(text: $searchText, prompt: LocalString.common_search)
        .onChange(of: category) { selection.reset() }
        .onChange(of: searchText) { _, newValue in
            sections.nsPredicate = ZimFilesCategory
                .buildPredicate(category: category, searchText: newValue, languageCode: selectedLanguage)
        }
        .onChange(of: selectedLanguage) {
            sections.nsPredicate = ZimFilesCategory
                .buildPredicate(category: category, searchText: searchText, languageCode: selectedLanguage)
        }
        .onChange(of: languageCodes) {
            if !languageCodes.contains(selectedLanguage) {
                selectedLanguage = languageCodes.first ?? "eng"
            }
        }
    }

    private var gridItem: GridItem {
        if horizontalSizeClass == .regular {
            return GridItem(.adaptive(minimum: 200, maximum: 400), spacing: 12)
        } else {
            return GridItem(.adaptive(minimum: 175, maximum: 400), spacing: 12)
        }
    }

    private struct SectionHeader: View {
        let title: String
        let category: Category
        let imageData: Data?
        let imageURL: URL?

        var body: some View {
            Label {
                Text(title).font(.title3).fontWeight(.semibold)
            } icon: {
                Favicon(category: category, imageData: imageData, imageURL: imageURL).frame(height: 20)
            }
        }
    }
}

private struct CategoryList: View {
    @Binding var category: Category
    @Binding var selectedLanguage: String
    @Binding var searchText: String
    @Default(.libraryLanguageCodes) private var languageCodes
    @EnvironmentObject private var selection: SelectedZimFileViewModel
    @FetchRequest private var zimFiles: FetchedResults<ZimFile>
    private let dismiss: (() -> Void)?

    init(category: Binding<Category>,
         selectedLanguage: Binding<String>,
         searchText: Binding<String>,
         dismiss: (() -> Void)?
    ) {
        self._selectedLanguage = selectedLanguage
        self._category = category
        self._searchText = searchText
        self.dismiss = dismiss
        self._zimFiles = FetchRequest<ZimFile>(
            sortDescriptors: [
                NSSortDescriptor(
                    key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare)
                ),
                NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)
            ],
            predicate: ZimFilesCategory.buildPredicate(
                category: category.wrappedValue,
                searchText: searchText.wrappedValue,
                languageCode: selectedLanguage.wrappedValue
            ),
            animation: .easeInOut
        )
    }

    var body: some View {
        Group {
            if zimFiles.isEmpty {
                CategoryEmptySection()
            } else {
                List(zimFiles, id: \.self, selection: $selection.selectedZimFile) { zimFile in
                    LibraryZimFileContext(
                        content: { ZimFileRow(zimFile) },
                        zimFile: zimFile,
                        selection: selection,
                        dismiss: dismiss)
                }
                #if os(macOS)
                .listStyle(.inset)
                #elseif os(iOS)
                .listStyle(.plain)
                #endif
            }
        }
        .searchable(text: $searchText, prompt: LocalString.common_search)
        .onChange(of: category) { selection.reset() }
        .onChange(of: searchText) { _, newValue in
            zimFiles.nsPredicate = ZimFilesCategory
                .buildPredicate(
                    category: category,
                    searchText: newValue,
                    languageCode: selectedLanguage
                )
        }
        .onChange(of: selectedLanguage) {
            zimFiles.nsPredicate = ZimFilesCategory
                .buildPredicate(
                    category: category,
                    searchText: searchText,
                    languageCode: selectedLanguage
                )
        }
        .onChange(of: languageCodes) {
            if !languageCodes.contains(selectedLanguage) {
                selectedLanguage = languageCodes.first ?? "eng"
            }
        }
    }
}
