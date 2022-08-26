//
//  ZimFilesCategories.swift
//  Kiwix
//
//  Created by Chris Li on 8/7/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

/// A grid of zim files under each category.
struct ZimFilesCategories: View {
    @State private var selected: Category = .wikipedia
    
    var body: some View {
        ZimFilesCategory(category: $selected)
            .navigationTitle(NavigationItem.categories.name)
            .toolbar {
                Picker("Category", selection: $selected) {
                    ForEach(Category.allCases) { Text($0.name).tag($0) }
                }
            }
    }
}

/// A grid of list of zim files under a single category.
struct ZimFilesCategory: View {
    @Binding var category: Category
    @State private var searchText = ""
    
    var body: some View {
        if #available(iOS 15.0, *), category != .ted, category != .stackExchange, category != .other {
            CategoryGrid(category: $category, searchText: $searchText)
        } else {
            CategoryList(category: $category, searchText: $searchText)
        }
    }
    
    static func buildPredicate(category: Category, searchText: String) -> NSPredicate {
        var predicates = [
            NSPredicate(format: "category == %@", category.rawValue),
            NSPredicate(format: "languageCode IN %@", Defaults[.libraryLanguageCodes]),
            NSPredicate(format: "requiresServiceWorkers == false")
        ]
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

@available(iOS 15.0, macOS 12.0, *)
private struct CategoryGrid: View {
    @Binding var category: Category
    @Binding var searchText: String
    @Default(.libraryLanguageCodes) private var languageCodes
    @SectionedFetchRequest private var sections: SectionedFetchResults<String, ZimFile>
    @State private var selected: ZimFile?
    
    init(category: Binding<Category>, searchText: Binding<String>) {
        self._category = category
        self._searchText = searchText
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
                Message(text: "No zim file under this category.")
            } else {
                LazyVGrid(
                    columns: ([gridItem]),
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(sections) { section in
                        if sections.count <= 1 {
                            ForEach(section) { zimFile in
                                Button { selected = zimFile } label: { ZimFileCell(zimFile, prominent: .size) }
                                    .buttonStyle(.plain)
                                    .modifier(ZimFileContextMenu(selected: $selected, zimFile: zimFile))
                                    .modifier(ZimFileSelection(selected: $selected, zimFile: zimFile))
                            }
                        } else {
                            Section {
                                ForEach(section) { zimFile in
                                    Button { selected = zimFile } label: { ZimFileCell(zimFile, prominent: .size) }
                                        .buttonStyle(.plain)
                                        .modifier(ZimFileContextMenu(selected: $selected, zimFile: zimFile))
                                        .modifier(ZimFileSelection(selected: $selected, zimFile: zimFile))
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
                    }
                }.modifier(GridCommon())
            }
        }
        .modifier(ZimFileDetailPanel_macOS(zimFile: selected))
        .modifier(Searchable(searchText: $searchText))
        .onChange(of: category) { _ in selected = nil }
        .onChange(of: searchText) { _ in
            sections.nsPredicate = ZimFilesCategory.buildPredicate(category: category, searchText: searchText)
        }
        .onChange(of: languageCodes) { _ in
            sections.nsPredicate = ZimFilesCategory.buildPredicate(category: category, searchText: searchText)
        }
    }
    
    private var gridItem: GridItem {
        #if os(macOS)
        GridItem(.adaptive(minimum: 200, maximum: 400), spacing: 12)
        #elseif os(iOS)
        GridItem(.adaptive(minimum: 175, maximum: 400), spacing: 12)
        #endif
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
    @FetchRequest private var zimFiles: FetchedResults<ZimFile>
    @State private var selected: ZimFile?
    
    init(category: Binding<Category>, searchText: Binding<String>) {
        self._category = category
        self._searchText = searchText
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
                Message(text: "No zim file under this category.")
            } else {
                List(zimFiles, id: \.self, selection: $selected) { zimFile in
                    ZimFileRow(zimFile)
                        .modifier(ZimFileContextMenu(selected: $selected, zimFile: zimFile))
                        .modifier(ZimFileSelection(selected: $selected, zimFile: zimFile))
                }.modifier(ListStyle())
            }
        }
        .modifier(ZimFileDetailPanel_macOS(zimFile: selected))
        .modifier(Searchable(searchText: $searchText))
        .onChange(of: category) { _ in selected = nil }
        .onChange(of: searchText) { _ in
            if #available(iOS 15.0, *) {
                zimFiles.nsPredicate = ZimFilesCategory.buildPredicate(category: category, searchText: searchText)
            }
        }
        .onChange(of: languageCodes) { _ in
            if #available(iOS 15.0, *) {
                zimFiles.nsPredicate = ZimFilesCategory.buildPredicate(category: category, searchText: searchText)
            }
        }
    }
    
    private struct ListStyle: ViewModifier {
        func body(content: Content) -> some View {
            #if os(macOS)
            content.listStyle(.inset)
            #elseif os(iOS)
            content.listStyle(.plain)
            #endif
        }
    }
}

