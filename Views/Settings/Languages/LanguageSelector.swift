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

import Defaults
import SwiftUI

struct LanguageSelector: View {
#if os(macOS)
    @FocusState var isSearchFocused: Bool
    @EnvironmentObject private var library: LibraryViewModel
    private let isSearching = false // never changes for macOS
#else
    @State private var isSearching = false
#endif
    @State private var sortOrder = KeyPathComparator(\Language.count, order: .reverse)
    
    @State private var showing = [Language]()
    @State private var hiding = [Language]()
    @State private var languages = [Language]()
    @State private var searchText: String = ""
    
    #if os(macOS)
    @ViewBuilder
    private func itemToShow(_ language: Language) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal")
            LanguageLabel(language: language)
            Button(role: .destructive) {
                hide(language)
            } label: {
                Image(systemName: "checkmark.square")
            }
            .buttonStyle(.borderless)
            .opacity(showing.count <= 1 ? 0 : 1)
        }
    }
    
    @ViewBuilder
    private func searchHeader() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("", text: $searchText, prompt: Text(LocalString.common_search))
                .focused($isSearchFocused)
                .onKeyPress(.escape) {
                    isSearchFocused.toggle()
                    searchText = ""
                    return .handled
                }
        }
        Spacer()
    }
    #endif
    
    #if os(iOS)
    @ViewBuilder
    private func itemToShow(_ language: Language) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal")
            Button { hide(language) } label: { LanguageLabel(language: language) }
        }
    }
    #endif
    
    var body: some View {
        List {
            if !isSearching {
                Section {
                    if showing.isEmpty {
                        Text(LocalString.language_selector_no_language_title).foregroundColor(.secondary)
                    } else {
                        ForEach(showing) { language in
                            itemToShow(language)
                                .onDrag { NSItemProvider() }
                        }
                        .onMove(perform: onMoveLanguage)
                    }
                } header: { Text(LocalString.language_selector_showing_header) }
            }
            Section {
                ForEach(hiding) { language in
                    Button { show(language) } label: { LanguageLabel(language: language) }
                }
            } header: {
                HStack {
                    Text(LocalString.language_selector_hiding_header)
                    Spacer()
#if os(macOS)
                    searchHeader()
#endif
                    LanguageSortControls(keyPathCompare: $sortOrder)
                }
            }
        }
#if os(iOS)
        .listStyle(.insetGrouped)
        .navigationTitle(LocalString.language_selector_navitation_title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, isPresented: $isSearching, prompt: LocalString.common_search)
#else
        .disabled(library.state == .inProgress)
#endif
        .onAppear {
            Task {
                languages = await Languages.fetch()
                let userSelected = Set(Defaults[.libraryLanguageCodes])
                showing = languages.filter { userSelected.contains($0.code) }
                hiding = hidingLanguages(searchText: searchText)
            }
        }
        .onChange(of: sortOrder) { _, newValue in
            hiding.sort(using: [newValue])
        }
        .onChange(of: searchText) { _, newValue in
            hiding = hidingLanguages(searchText: newValue)
        }
    }
    
    private func hidingLanguages(searchText: String) -> [Language] {
        let userSelected = Set(Defaults[.libraryLanguageCodes])
        return languages.filter { (lang: Language) in
            guard !userSelected.contains(lang.code) else { return false }
            guard !searchText.isEmpty else { return true }
            return lang.name.lowercased().contains(searchText.lowercased())
        }.sorted(using: sortOrder)
    }
    
    private func onMoveLanguage(from source: IndexSet, to destination: Int) {
        showing.move(fromOffsets: source, toOffset: destination)
        Defaults[.libraryLanguageCodes] = showing.map { $0.code }
    }
    
    private func show(_ language: Language) {
        Defaults[.libraryLanguageCodes].append(language.code)
        withAnimation {
            hiding.removeAll { $0.code == language.code }
            showing.append(language)
        }
    }
    
    private func hide(_ language: Language) {
        guard Defaults[.libraryLanguageCodes].count > 1 else {
            // we should not remove all languages, it will produce empty results
            return
        }
        Defaults[.libraryLanguageCodes].removeAll(where: { $0 == language.code })
        withAnimation {
            showing.removeAll { $0.code == language.code }
            hiding.append(language)
            hiding.sort(using: sortOrder)
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
