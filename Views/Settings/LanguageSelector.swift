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
    @State private var searchText: String = ""
    @State private var onlySelected: Bool = false

    var body: some View {
        VStack {
            HStack {
                TextField("", text: $searchText, prompt: Text(LocalString.common_search))
                Toggle(isOn: $onlySelected, label: {
                    Label("", systemImage: "checkmark.square")
                        .labelStyle(.iconOnly)
                })
            }
            Table(languages, sortOrder: $sortOrder) {
                TableColumn("") { language in
                    Toggle("", isOn: Binding {
                        selected.contains(language.code)
                    } set: { isSelected in
                        if isSelected {
                            selected.insert(language.code)
                            reloadLanguages()
                        } else if selected.count > 1 {
                            selected.remove(language.code)
                            reloadLanguages()
                        }
                    })
                }.width(14)
                TableColumn(LocalString.language_selector_name_title, value: \.name)
                TableColumn(LocalString.language_selector_count_table_title, value: \.count) { language in
                    Text(language.count.formatted())
                }
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
        .onChange(of: searchText) { _, _ in
            reloadLanguages()
        }
        .onChange(of: onlySelected) { _, _ in
            reloadLanguages()
        }
    }
    
    private func reloadLanguages() {
        reloadLanguages(searchText: searchText, onlySelected: onlySelected)
    }

    private func reloadLanguages(searchText: String, onlySelected: Bool) {
        Task {
            languages = await Languages.fetch()
            languages.sort(using: sortOrder)
            switch (searchText.isEmpty, onlySelected) {
            case (true, false):
                // nothing to filter
                return
            case (true, true):
                // show only selected no search
                languages = languages.filter { (lang: Language) in
                    selected.contains(lang.code)
                }
            case (false, false):
                // search by text, show all
                languages = languages.filter { (lang: Language) in
                    lang.name.lowercased().contains(searchText.lowercased())
                }
            case (false, true):
                // search by text, but show only selected
                languages = languages.filter { (lang: Language) in
                    lang.name.lowercased().contains(searchText.lowercased()) && selected.contains(lang.code)
                }
            }
        }
    }
}
#elseif os(iOS)
struct LanguageSelector: View {
    @Default(.libraryLanguageSortingMode) private var sortingMode
    @State private var showing = [Language]()
    @State private var hiding = [Language]()
    @State private var languages = [Language]()
    @State private var searchText: String = ""

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
            ToolbarItem(placement: .secondaryAction) {
                Picker(selection: $sortingMode) {
                    ForEach(LibraryLanguageSortingMode.allCases) { sortingMode in
                        Text(sortingMode.name).tag(sortingMode)
                    }
                } label: {
                    Label(LocalString.language_selector_toolbar_sorting, systemImage: "arrow.up.arrow.down")
                        .labelStyle(.iconOnly)
                }
            }
        }
        .onAppear {
            Task {
                languages = await Languages.fetch()
                languages.sort(by: Languages.compare(lhs:rhs:))
                showing = languages.filter { Defaults[.libraryLanguageCodes].contains($0.code) }
                hiding = hidingLanguages(searchText: searchText)
            }
        }
        .onChange(of: sortingMode) {
            showing.sort(by: Languages.compare(lhs:rhs:))
            hiding.sort(by: Languages.compare(lhs:rhs:))
        }
        .searchable(text: $searchText, prompt: LocalString.common_search)
        .onChange(of: searchText) { _, newValue in
            hiding = hidingLanguages(searchText: newValue)
        }
    }
    
    private func hidingLanguages(searchText: String) -> [Language] {
        languages.filter { (lang: Language) in
            guard !Defaults[.libraryLanguageCodes].contains(lang.code) else { return false }
            guard !searchText.isEmpty else { return true }
            return lang.name.lowercased().contains(searchText.lowercased())
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

enum Languages {
    /// Retrieve a list of languages.
    /// - Returns: languages with count of zim files in each language
    static func fetch() async -> [Language] {
        let languages: [Language] = await Database.shared.viewContext.perform {
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
            fetchRequest.predicate = ZimFile.Predicate.notDownloaded()
            fetchRequest.propertiesToFetch = ["languageCode", count]
            fetchRequest.propertiesToGroupBy = ["languageCode"]
            fetchRequest.resultType = .dictionaryResultType
            
            guard let results = try? fetchRequest.execute() else {
                return []
            }
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
        return languages
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
