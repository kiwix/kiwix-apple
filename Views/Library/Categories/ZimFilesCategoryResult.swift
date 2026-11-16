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
        .onChange(of: categoryBy) {
            selection.reset() // reset the ZIM selection in macOS sidebar
            results.nsPredicate = ZimFilesCategoryResult
                .buildPredicate(by: categoryBy, languageCode: selectedLanguage)
        }
        .onChange(of: selectedLanguage) {
            selection.reset() // reset the ZIM selection in macOS sidebar
            results.nsPredicate = ZimFilesCategoryResult
                .buildPredicate(by: categoryBy, languageCode: selectedLanguage)
        }
        .onChange(of: languageCodes) {
            if !languageCodes.contains(selectedLanguage) {
                selection.reset() // reset the ZIM selection in macOS sidebar
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
        switch self {
        case .category(let category):
            return category.name
        case .search:
            return LocalString.search_result_header_text
        }
    }
}
