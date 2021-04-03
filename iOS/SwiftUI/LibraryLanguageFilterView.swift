//
//  LibraryLanguageFilterView.swift
//  Kiwix
//
//  Created by Chris Li on 4/3/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct LibraryLanguageFilterView: View {
    @AppStorage("libraryLanguageSortingMode") var sortingMode: LibraryLanguageFilterSortingMode = .alphabetically
    
    @ObservedObject private var viewModel = ViewModel()
    var doneButtonTapped: () -> Void = {}
    
    var body: some View {
        List {
            if viewModel.showing.count > 0 {
                Section(header: Text("Showing")) {
                    ForEach(viewModel.showing) { LanguageCell(language: $0) }
                }
            }
            if viewModel.hiding.count > 0 {
                Section(header: Text("Hiding")) {
                    ForEach(viewModel.hiding) { LanguageCell(language: $0) }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done", action: doneButtonTapped)
            }
            ToolbarItem(placement: ToolbarItemPlacement.principal) {
                Picker("Language Sorting Mode", selection: $sortingMode, content: {
                    Text("A-Z").tag(LibraryLanguageFilterSortingMode.alphabetically)
                    Text("By Count").tag(LibraryLanguageFilterSortingMode.byCount)
                })
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
    
    struct Language: Identifiable, Comparable {
        var id: String { code }
        let code: String
        let name: String
        let count: Int
        
        init?(code: String, count: Int) {
            guard let name = Locale.current.localizedString(forLanguageCode: code) else { return nil }
            self.code = code
            self.name = name
            self.count = count
        }
        
        static func < (lhs: LibraryLanguageFilterView.Language, rhs: LibraryLanguageFilterView.Language) -> Bool {
            switch lhs.name.caseInsensitiveCompare(rhs.name) {
            case .orderedAscending:
                return true
            case .orderedDescending:
                return false
            case .orderedSame:
                return lhs.count > rhs.count
            }
        }
    }
    
    @available(iOS 14.0, *)
    struct LanguageCell: View {
        let language: Language
        var body: some View {
            HStack {
                Text(language.name)
                Spacer()
                Text("\(language.count)").foregroundColor(.secondary)
            }
        }
    }
    
    class ViewModel: ObservableObject {
        @AppStorage("libraryLanguageSortingMode") var sortingMode: LibraryLanguageFilterSortingMode = .alphabetically
        @Published private(set) var showing: [Language] = []
        @Published private(set) var hiding: [Language] = []
        
        init() {
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    var showing: [Language] = []
                    var hiding: [Language] = []
                    let showinglanguageCodes = UserDefaults.standard.libraryFilterLanguageCodes
                    
                    let database = try Realm()
                    let codes = database.objects(ZimFile.self).distinct(by: ["languageCode"]).map({ $0.languageCode })
                    for code in codes {
                        let count = database.objects(ZimFile.self).filter("languageCode = %@", code).count
                        guard let language = Language(code: code, count: count) else { continue }
                        if showinglanguageCodes.contains(code) {
                            showing.append(language)
                        } else {
                            hiding.append(language)
                        }
                    }
                    
                    self.sort(&showing)
                    self.sort(&hiding)
                    
                    DispatchQueue.main.async {
                        self.showing = showing
                        self.hiding = hiding
                    }
                } catch {}
            }
        }
        
        private func sort(_ languages: inout [Language]) {
            switch sortingMode {
            case .alphabetically:
                languages.sort { $0 < $1 }
            case .byCount:
                languages.sort {
                    if $0.count == $1.count {
                        return $0 < $1
                    } else {
                        return $0.count > $1.count
                    }
                }
            }
        }
    }
}

