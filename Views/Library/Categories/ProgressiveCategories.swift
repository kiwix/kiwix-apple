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

#if os(iOS)
import CoreData
import Defaults
import Foundation
import SwiftUI

struct ProgressiveCategories: View {
    
    @State private var selectedLang: String
    @Default(.libraryLanguageCodes) private var libraryLanguageCodes
    @State private var categories: [Category]
    
    init() {
        let selectedCode = Defaults[.libraryLanguageCodes].first ?? "eng"
        self.selectedLang = selectedCode
        self.categories = CategoriesToLanguages().categoriesIn(languageCode: selectedCode)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                ForEach(categories) { category in
                    CategorySection(category: category, selectedLanguage: selectedLang)
                }
            }
            .padding(.top, 16)
        }
        .navigationTitle(MenuItem.explore.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedLang) { _, newValue in
            categories = CategoriesToLanguages().categoriesIn(languageCode: newValue)
        }
    }
}

struct CategorySection: View {
    private let category: Category
    @FetchRequest private var results: FetchedResults<ZimFile>
    @Environment(\.layoutDirection) var layoutDirection
    
    init(category: Category, selectedLanguage: String) {
        self.category = category
        self._results = FetchRequest(
            fetchRequest: Self.fetchRequest(category: category, languageCode: selectedLanguage, limit: 3)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(category.name)
                    .font(.title2)
                    .bold()
                Image(systemName: layoutDirection == .leftToRight ? "chevron.right" : "chevron.left")
            }
            .padding(.leading, 16)
            ForEach(results, id: \.fileID) { zimFile in
                ZimFileCell(zimFile, isSelected: false)
            }
        }
    }
    
    @MainActor
    static func fetchRequest(category: Category, languageCode: String, limit: Int) -> NSFetchRequest<ZimFile> {
        let request: NSFetchRequest<ZimFile> = ZimFile.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ZimFile.name, ascending: true),
            NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)
        ]
        request.predicate = Self.buildPredicate(
            category: category,
            languageCode: languageCode
        )
        request.fetchLimit = limit
        return request
    }
    
    @MainActor
    static func buildPredicate(
        category: Category,
        languageCode: String
    ) -> NSPredicate {
        let regex = String(format: "(.*,)?%@(,.*)?", languageCode)
        let langPredicate = NSPredicate(format: "languageCode MATCHES %@", regex)
        var predicates: [NSPredicate] = []
        predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "flavor == %@", "maxi"),
            NSPredicate(format: "flavor == %@", "")
        ]))
        predicates.append(ZimFile.Predicate.notDownloaded())
        predicates.append(langPredicate)
        predicates.append(NSPredicate(format: "requiresServiceWorkers == false"))
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}


//
//struct SearchPlacementModifier: ViewModifier {
//    func body(content: Content) -> some View {
//        if #available(iOS 26, *) {
//            content.searchPresentationToolbarBehavior(.avoidHidingContent)
//        } else {
//            content
//        }
//    }
//    
//}


#endif
