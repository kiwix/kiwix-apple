//
//  LanguageSelector.swift
//  Kiwix
//
//  Created by Chris Li on 7/10/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI

import Defaults

#if os(macOS)
struct LanguageSelector: View {
    @Default(.libraryLanguageCodes) private var selected
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
                    } else {
                        selected.remove(language.code)
                    }
                })
            }.width(14)
            TableColumn("language_selector.name.title".localized, value: \.name)
            TableColumn("language_selector.count.table.title".localized, value: \.count) { language in
                Text(language.count.formatted())
            }
        }
        .tableStyle(.bordered(alternatesRowBackgrounds: true))
        .onChange(of: sortOrder) { languages.sort(using: $0) }
        .task {
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
                    Text("language_selector.no_language.title".localized).foregroundColor(.secondary)
                } else {
                    ForEach(showing) { language in
                        Button { hide(language) } label: { LanguageLabel(language: language) }
                    }
                }
            } header: { Text("language_selector.showing.header".localized) }
            Section {
                ForEach(hiding) { language in
                    Button { show(language) } label: { LanguageLabel(language: language) }
                }
            } header: { Text("language_selector.hiding.header".localized) }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("language_selector.navitation.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Picker(selection: $sortingMode) {
                ForEach(LibraryLanguageSortingMode.allCases) { sortingMode in
                    Text(sortingMode.name.localized).tag(sortingMode)
                }
            } label: {
                Label("language_selector.toolbar.sorting".localized, systemImage: "arrow.up.arrow.down")
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
        .onChange(of: sortingMode) { _ in
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

private class Languages {
    /// Retrieve a list of languages.
    /// - Returns: languages with count of zim files in each language
    static func fetch() async -> [Language] {
        let count = NSExpressionDescription()
        count.name = "count"
        count.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "languageCode")])
        count.expressionResultType = .integer16AttributeType
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ZimFile")
        fetchRequest.propertiesToFetch = ["languageCode", count]
        fetchRequest.propertiesToGroupBy = ["languageCode"]
        fetchRequest.resultType = .dictionaryResultType
        
        let languages: [Language] = await withCheckedContinuation { continuation in
            let context = Database.shared.container.newBackgroundContext()
            context.perform {
                guard let results = try? context.fetch(fetchRequest) else {
                    continuation.resume(returning: [])
                    return
                }
                let language: [Language] = results.compactMap { result in
                    guard let result = result as? NSDictionary,
                          let languageCode = result["languageCode"] as? String,
                          let count = result["count"] as? Int else { return nil }
                    return Language(code: languageCode, count: count)
                }
                continuation.resume(returning: language)
            }
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
