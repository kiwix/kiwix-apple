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
    @Default(.hasSeenCategories) private var hasSeenCategories
    private var categories: [Category]
    private let dismiss: (() -> Void)?

    init(
        dismiss: (() -> Void)?,
        categories: [Category] = CategoriesToLanguages().allCategories()
    ) {
        self.categories = categories
        selected = categories.first ?? .wikipedia
        self.dismiss = dismiss
    }

    var body: some View {
        ZimFilesCategory(category: $selected, dismiss: dismiss)
            .modifier(ToolbarRoleBrowser())
            .navigationTitle(MenuItem.categories.name)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    if #unavailable(iOS 16) {
                        Button {
                            NotificationCenter.toggleSidebar()
                        } label: {
                            Label(LocalString.zim_file_opened_toolbar_show_sidebar_label, systemImage: "sidebar.left")
                        }
                    }
                }
                #endif
                ToolbarItem {
                    Picker(LocalString.zim_file_category_title, selection: $selected) {
                        ForEach(categories) {
                            Text($0.name).tag($0)
                        }
                    }
                }
            }.onAppear {
                LibraryViewModel().start(isUserInitiated: false)
            }
            .onDisappear {
                hasSeenCategories = true
            }
    }
}

/// A grid or list of zim files under a single category.
struct ZimFilesCategory: View {
    @Binding var category: Category
    @State private var searchText = ""
    let dismiss: (() -> Void)? // iOS only

    var body: some View {
        if category == .ted || category == .stackExchange || category == .other {
            CategoryList(category: $category, searchText: $searchText, dismiss: dismiss)
        } else {
            CategoryGrid(category: $category, searchText: $searchText, dismiss: dismiss)
        }
    }

    @MainActor
    static func buildPredicate(
        category: Category,
        searchText: String,
        languageCodes: Set<String> = Defaults[.libraryLanguageCodes]
    ) -> NSPredicate {
        let langPredicates = languageCodes.map { langCode -> NSPredicate in
            let regex = String(format: "(.*,)?%@(,.*)?", langCode)
            return NSPredicate(format: "languageCode MATCHES %@", regex)
        }
        var predicates = [
            NSPredicate(format: "category == %@", category.rawValue),
            NSCompoundPredicate(orPredicateWithSubpredicates: langPredicates),
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
    @Binding var searchText: String
    @Default(.libraryLanguageCodes) private var languageCodes
    @EnvironmentObject private var viewModel: LibraryViewModel
    @EnvironmentObject private var selection: SelectedZimFileViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @SectionedFetchRequest private var sections: SectionedFetchResults<String, ZimFile>
    private let dismiss: (() -> Void)? // iOS only

    init(category: Binding<Category>, searchText: Binding<String>, dismiss: (() -> Void)?) {
        self._category = category
        self._searchText = searchText
        self.dismiss = dismiss
        self._sections = SectionedFetchRequest<String, ZimFile>(
            sectionIdentifier: \.name,
            sortDescriptors: [SortDescriptor(\ZimFile.name), SortDescriptor(\.size, order: .reverse)],
            predicate: ZimFilesCategory.buildPredicate(
                category: category.wrappedValue, searchText: searchText.wrappedValue
            ),
            animation: .easeInOut
        )
    }

    var body: some View {
        Group {
            if sections.isEmpty {
                switch viewModel.state {
                case .inProgress:
                    Message(text: LocalString.zim_file_catalog_fetching_message)
                case .error:
                    Message(text: LocalString.library_refresh_error_retrieve_description, color: .red)
                case .initial, .complete:
                    Message(text: LocalString.zim_file_category_section_empty_message)
                }
            } else {
                LazyVGrid(columns: ([gridItem]), alignment: .leading, spacing: 12) {
                    ForEach(sections) { section in
                        Section {
                            ForEach(section) { zimFile in
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
        .searchable(text: $searchText)
        .onChange(of: category) { _ in selection.reset() }
        .onChange(of: searchText) { _ in
            sections.nsPredicate = ZimFilesCategory.buildPredicate(category: category, searchText: searchText)
        }
        .onChange(of: languageCodes) { _ in
            sections.nsPredicate = ZimFilesCategory.buildPredicate(category: category, searchText: searchText)
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
    @Binding var searchText: String
    @Default(.libraryLanguageCodes) private var languageCodes
    @EnvironmentObject private var viewModel: LibraryViewModel
    @EnvironmentObject private var selection: SelectedZimFileViewModel
    @FetchRequest private var zimFiles: FetchedResults<ZimFile>
    private let dismiss: (() -> Void)?

    init(category: Binding<Category>, 
         searchText: Binding<String>,
         dismiss: (() -> Void)?
    ) {
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
                category: category.wrappedValue, searchText: searchText.wrappedValue
            ),
            animation: .easeInOut
        )
    }

    var body: some View {
        Group {
            if zimFiles.isEmpty {
                switch viewModel.state {
                case .inProgress:
                    Message(text: LocalString.zim_file_catalog_fetching_message)
                case .error:
                    Message(text: LocalString.library_refresh_error_retrieve_description, color: .red)
                case .initial, .complete:
                    Message(text: LocalString.zim_file_category_section_empty_message)
                }
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
        .searchable(text: $searchText)
        .onChange(of: category) { _ in selection.reset() }
        .onChange(of: searchText) { _ in
            zimFiles.nsPredicate = ZimFilesCategory.buildPredicate(category: category, searchText: searchText)
        }
        .onChange(of: languageCodes) { _ in
            zimFiles.nsPredicate = ZimFilesCategory.buildPredicate(category: category, searchText: searchText)
        }
    }
}
