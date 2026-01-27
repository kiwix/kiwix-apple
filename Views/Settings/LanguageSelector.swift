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
import SwiftUI

import Defaults

#if os(macOS)
struct LanguageSelector: View {
    @Default(.libraryLanguageCodes) private var selected
    @EnvironmentObject private var library: LibraryViewModel
    @State private var languages = [Language]()
    @State private var sortOrder = [KeyPathComparator(\Language.count, order: .reverse)]

    var body: some View {
        Table(languages, sortOrder: $sortOrder) {
            TableColumn("") { language in
                Toggle("", isOn: Binding {
                    selected.contains(language.code)
                } set: { isSelected in
                    if isSelected {
                        selected.insert(language.code)
                    } else if selected.count > 1 {
                        selected.remove(language.code)
                    }
                })
            }.width(14)
            TableColumn(LocalString.language_selector_name_title, value: \.name)
            TableColumn(LocalString.language_selector_count_table_title, value: \.count) { language in
                Text(language.count.formatted())
            }
        }
        .opacity( library.state == .complete ? 1.0 : 0.3)
        .tableStyle(.bordered(alternatesRowBackgrounds: true))
        .onChange(of: sortOrder) { _, newValue in languages.sort(using: newValue) }
        .onChange(of: library.state) { _, state in
            guard state != .inProgress else { return }
            reloadLanguages()
        }
        .onAppear {
            reloadLanguages()
        }
    }

    private func reloadLanguages() {
        Task {
            languages = await Languages.fetch()
            languages.sort(using: sortOrder)
        }
    }
}
#elseif os(iOS)
struct LanguageSelector: View {
    @Default(.libraryLanguageSortingMode) private var sortingMode
    @State private var showing = [Language]()
    @State private var hiding = [Language]()

    var body: some View {
        List {
            Section {
                if showing.isEmpty {
                    Text(LocalString.language_selector_no_language_title).foregroundColor(.secondary)
                } else {
                    ForEach(showing) { language in
                        Button { hide(language) } label: { LanguageLabel(language: language) }
                    }
                }
            } header: { Text(LocalString.language_selector_showing_header) }
            Section {
                ForEach(hiding) { language in
                    Button { show(language) } label: { LanguageLabel(language: language) }
                }
            } header: { Text(LocalString.language_selector_hiding_header) }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(LocalString.language_selector_navitation_title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Picker(selection: $sortingMode) {
                ForEach(LibraryLanguageSortingMode.allCases) { sortingMode in
                    Text(sortingMode.name).tag(sortingMode)
                }
            } label: {
                Label(LocalString.language_selector_toolbar_sorting, systemImage: "arrow.up.arrow.down")
            }.pickerStyle(.menu)
        }
        .onAppear {
            Task {
                var languages = await Languages.fetch()
                languages.sort(by: Languages.compare(lhs:rhs:))
                showing = languages.filter { Defaults[.libraryLanguageCodes].contains($0.code) }
                hiding = languages.filter { !Defaults[.libraryLanguageCodes].contains($0.code) }
            }
        }
        .onChange(of: sortingMode) {
            showing.sort(by: Languages.compare(lhs:rhs:))
            hiding.sort(by: Languages.compare(lhs:rhs:))
        }
    }

    private func show(_ language: Language) {
        Defaults[.libraryLanguageCodes].insert(language.code)
        withAnimation {
            hiding.removeAll { $0.code == language.code }
            showing.append(language)
            showing.sort(by: Languages.compare(lhs:rhs:))
        }
    }

    private func hide(_ language: Language) {
        guard Defaults[.libraryLanguageCodes].count > 1 else {
            // we should not remove all languages, it will produce empty results
            return
        }
        Defaults[.libraryLanguageCodes].remove(language.code)
        withAnimation {
            showing.removeAll { $0.code == language.code }
            hiding.append(language)
            hiding.sort(by: Languages.compare(lhs:rhs:))
        }
    }
}

private struct LanguageLabel: View {
    let language: Language

    var body: some View {
        HStack {
            Text(language.name).foregroundColor(.primary)
            Spacer()
            Text("\(language.count)").foregroundColor(.secondary)
        }
    }
}
#endif

class Languages {
    /// Retrieve a list of languages.
    /// - Returns: languages with count of zim files in each language
    static func fetch() async -> [Language] {
        
        let backgroundContext = Database.shared.backgroundContext
        let languages: [Language]? = try? await backgroundContext.perform {
            let count = NSExpressionDescription()
            count.name = "count"
            count.expression = NSExpression(
                forFunction: "count:",
                arguments: [NSExpression(forKeyPath: "languageCode")]
            )
            count.expressionResultType = .integer16AttributeType
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ZimFile")
            // exclude the already downloaded files, they might have invalid language set
            // but we are mainly interested in fetched content
            fetchRequest.predicate = ZimFile.Predicate.notDownloaded
            fetchRequest.propertiesToFetch = ["languageCode", count]
            fetchRequest.propertiesToGroupBy = ["languageCode"]
            fetchRequest.resultType = .dictionaryResultType
            let results = try fetchRequest.execute()
            let collector = LanguageCollector()
            for result in results {
                if let result = result as? NSDictionary,
                   let languageCodes = result["languageCode"] as? String,
                   let count = result["count"] as? Int {
                    collector.addLanguages(codes: languageCodes, count: count)
                }
            }
            return collector.languages()
        }
        return languages ?? []
    }

    /// Compare two languages based on library language sorting order.
    /// Can be removed once support for iOS 14 drops.
    /// - Parameters:
    ///   - lhs: one language to compare
    ///   - rhs: another language to compare
    /// - Returns: if one language should appear before or after another
    static func compare(lhs: Language, rhs: Language) -> Bool {
        switch Defaults[.libraryLanguageSortingMode] {
        case .alphabetically:
            return lhs.name.caseInsensitiveCompare(rhs.name) == .orderedAscending
        case .byCounts:
            return lhs.count > rhs.count
        }
    }
}
