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
import Foundation
import SwiftUI

struct CategoriesGrid: View {
    @State private var searchText = ""
    @State private var selectedLanguage: String
    @Default(.libraryLanguageCodes) private var libraryLanguageCodes
    @State private var categories: [Category]
    let dismiss: (@MainActor @Sendable () -> Void)?
    
    init(dismiss: (@MainActor @Sendable () -> Void)?) {
        let selectedCode = Defaults[.libraryLanguageCodes].first ?? "eng"
        self.dismiss = dismiss
        self.selectedLanguage = selectedCode
        self.categories = CategoriesToLanguages().categoriesIn(languageCode: selectedCode)
    }
    
    var body: some View {
        Group {
            if searchText.isEmpty {
                ScrollView {
                    CategorySection(title: "Categories") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 320)),
                                            GridItem(.adaptive(minimum: 160, maximum: 320))]) {
                            ForEach(categories) { category in
                                NavigationLink {
                                    ZimFileSingleCategory(
                                        category: category,
                                        selectedLanguage: $selectedLanguage,
                                        libraryLanguageCodes: libraryLanguageCodes,
                                        dimiss: self.dismiss
                                    )
                                } label: {
                                    CategoryGridCell(category: category)
                                }
                            }
                        }.padding(.horizontal)
                    }
                }
                .navigationTitle(MenuItem.explore.name)
            } else { // searching
                ZimFilesCategoryResult(categoryBy: CategoryBy.search(searchText),
                                       selectedLanguage: $selectedLanguage,
                                       dismiss: self.dismiss
                )
                .navigationTitle(LocalString.search_result_header_text)
            }
        }
        
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onChange(of: selectedLanguage) { _, newValue in
            categories = CategoriesToLanguages().categoriesIn(languageCode: newValue)
        }
        .searchable(text: $searchText, prompt: LocalString.common_search)
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                ToggleAroundLanguageButton(items: $libraryLanguageCodes, selection: $selectedLanguage)
                    .disabled($libraryLanguageCodes.count <= 1)
            }
#else
            if $languages.count > 1 {
                ToolbarItem(placement: .secondaryAction) {
                    ToggleAroundLanguageButton(items: $libraryLanguageCodes, selection: $selectedLanguage)
                }
            }
#endif
        }
        .onAppear {
            Task {
                await LibraryViewModel().start(isUserInitiated: false)
            }
        }
    }
}

struct CategorySection<Content: View>: View {
    private let title: String
    private let contentView: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        contentView = content
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title3)
                .bold()
                .multilineTextAlignment(.leading)
                .padding(.leading)
            contentView()
        }
    }
    
}

struct CategoryGridCell: View {
    let category: Category
    
    var body: some View {
        HStack {
            Text(category.name)
                .padding()
            Spacer()
        }
        .background(Color.secondaryBackground,
                    in: RoundedRectangle(
                        cornerSize: CGSize(width: 4, height: 4),
                        style: .continuous
                    ))
    }
    
}
