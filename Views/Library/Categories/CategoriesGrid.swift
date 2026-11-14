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
    @State private var selectedLanguage: String
    @Default(.libraryLanguageCodes) private var libraryLanguageCodes
    @State private var categories: [Category]
    let dismiss: (() -> Void)?
    
    init(dismiss: (@MainActor @Sendable () -> Void)?) {
        let selectedCode = Defaults[.libraryLanguageCodes].first ?? "eng"
        self.dismiss = dismiss
        self.selectedLanguage = selectedCode
        self.categories = CategoriesToLanguages().categoriesIn(languageCode: selectedCode)
    }
    
    var body: some View {
        ScrollView {
            CategorySection(title: "Categories") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 320)),
                                    GridItem(.adaptive(minimum: 160, maximum: 320))]) {
                    ForEach(categories) { category in
                        NavigationLink {
                            ZimFilesCategory(
                                category: Binding.constant(category),
                                searchText: Binding.constant(""),
                                selectedLanguage: $selectedLanguage,
                                dismiss: nil // TODO: hook up
                            )
                        } label: {
                            CategoryGridCell(category: category)
                        }
                        
                    }
                }
                                    .padding(.horizontal)
            }
        }
        .navigationTitle(MenuItem.explore.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onChange(of: selectedLanguage) { _, newValue in
            categories = CategoriesToLanguages().categoriesIn(languageCode: newValue)
        }
        .toolbar {
            if libraryLanguageCodes.count > 1 {
                ToolbarItem(id: "language_picker", placement: .confirmationAction) {
                    ToggleAroundLanguageButton(items: $libraryLanguageCodes, selection: $selectedLanguage)
                }
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
