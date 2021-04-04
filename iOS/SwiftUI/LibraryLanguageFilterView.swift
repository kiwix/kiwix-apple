//
//  LibraryLanguageFilterView.swift
//  Kiwix
//
//  Created by Chris Li on 4/3/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct LibraryLanguageFilterView: View {
    @ObservedObject private var viewModel = ViewModel()
    var doneButtonTapped: () -> Void = {}
    
    var body: some View {
        List {
            if viewModel.showing.count > 0 {
                Section(header: Text("Showing")) {
                    ForEach(viewModel.showing) { language in
                        Button(action: { viewModel.hide(language) }, label: {
                            LanguageCell(language: language)
                        })
                    }
                }
            }
            if viewModel.hiding.count > 0 {
                Section(header: Text("Hiding")) {
                    ForEach(viewModel.hiding) { language in
                        Button(action: { viewModel.show(language) }, label: {
                            LanguageCell(language: language)
                        })
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done", action: doneButtonTapped)
            }
            ToolbarItem(placement: ToolbarItemPlacement.principal) {
                Picker("Language Sorting Mode", selection: $viewModel.sortingMode, content: {
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
                Text(language.name).foregroundColor(.primary)
                Spacer()
                Text("\(language.count)").foregroundColor(.secondary)
            }
        }
    }
    
    class ViewModel: ObservableObject {
        @Published private(set) var showing: [Language] = []
        @Published private(set) var hiding: [Language] = []
        @Published var sortingMode: LibraryLanguageFilterSortingMode {
            didSet {
                UserDefaults.standard.set(sortingMode.rawValue, forKey: "libraryLanguageSortingMode")
                DispatchQueue.global(qos: .userInitiated).async { self.loadData() }
            }
        }
        
        init() {
            sortingMode = LibraryLanguageFilterSortingMode(
                rawValue: UserDefaults.standard.string(forKey: "libraryLanguageSortingMode") ?? ""
            ) ?? .alphabetically
            DispatchQueue.global(qos: .userInitiated).async { self.loadData() }
        }
        
        func show(_ language: Language) {
            withAnimation {
                self.showing.append(language)
                self.hiding.removeAll(where: { $0.code == language.code })
                
                showing = self.sorted(showing)
                hiding = self.sorted(hiding)
            }
        }
        
        func hide(_ language: Language) {
            withAnimation {
                self.showing.removeAll(where: { $0.code == language.code })
                self.hiding.append(language)
                
                showing = self.sorted(showing)
                hiding = self.sorted(hiding)
            }
        }
        
        private func loadData() {
            do {
                var showing: [Language] = []
                var hiding: [Language] = []
                let showinglanguageCodes = UserDefaults.standard.stringArray(forKey: "libraryFilterLanguageCodes") ?? []
                
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
                
                showing = self.sorted(showing)
                hiding = self.sorted(hiding)
                
                DispatchQueue.main.async {
                    self.showing = showing
                    self.hiding = hiding
                }
            } catch {}
        }
        
        private func sorted(_ languages: [Language]) -> [Language] {
            switch sortingMode {
            case .alphabetically:
                return languages.sorted { $0 < $1 }
            case .byCount:
                return languages.sorted { $0.count == $1.count ? $0 < $1 : $0.count > $1.count }
            }
        }
    }
}
