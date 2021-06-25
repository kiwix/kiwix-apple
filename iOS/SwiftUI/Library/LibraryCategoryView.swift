//
//  LibraryCategoryView.swift
//  Kiwix
//
//  Created by Chris Li on 4/4/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import Defaults
import RealmSwift

/// List of zim files under a single category,
@available(iOS 13.0, *)
struct LibraryCategoryView: View {
    @ObservedObject private var viewModel: ViewModel
    
    let category: ZimFile.Category
    var zimFileTapped: (String, String) -> Void = { _, _ in }
    
    init(category: ZimFile.Category) {
        self.category = category
        self._viewModel = ObservedObject(wrappedValue: ViewModel(category: category))
    }
    
    var body: some View {
        if viewModel.languages.isEmpty {
            InfoView(
                imageSystemName: "text.book.closed",
                title: "No Zim File",
                help: "Enable some other languages to see zim files under this category."
            )
        } else {
            List {
                ForEach(viewModel.languages) { language in
                    Section(header: viewModel.languages.count > 1 ? Text(language.name) : nil) {
                        ForEach(viewModel.zimFiles[language.code, default: []]) { zimFile in
                            Button(action: { zimFileTapped(zimFile.fileID, zimFile.title) }, label: {
                                ZimFileCell(zimFile, accessories: [.onDevice, .disclosureIndicator])
                            })
                        }
                    }
                }
            }
        }
    }
    
    struct Language: Identifiable {
        var id: String { code }
        let code: String
        let name: String
        
        init?(code: String) {
            guard let name = Locale.current.localizedString(forLanguageCode: code) else { return nil }
            self.code = code
            self.name = name
        }
    }
    
    class ViewModel: ObservableObject {
        @Published private(set) var languages: [Language] = []
        @Published private(set) var zimFiles = [String: [ZimFile]]()
        private var favicon = [URL: Data]()
        
        let category: ZimFile.Category
        private let queue = DispatchQueue(label: "org.kiwix.library.category", qos: .userInitiated)
        private var defaultsSubscriber: AnyCancellable?
        private var collectionSubscriber: AnyCancellable?
        
        init(category: ZimFile.Category) {
            self.category = category
            defaultsSubscriber = Defaults.publisher(.libraryLanguageCodes)
                .sink(receiveValue: { languageCodes in
                    self.loadData(languageCodes: languageCodes.newValue)
                    self.downloadFavicon(languageCodes: languageCodes.newValue)
                })
        }
        
        private func loadData(languageCodes: [String]) {
            let database = try? Realm()
            collectionSubscriber = database?.objects(ZimFile.self)
                .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "categoryRaw = %@", category.rawValue),
                    NSPredicate(format: "languageCode IN %@", languageCodes),
                ]))
                .sorted(by: [
                    SortDescriptor(keyPath: "title", ascending: true),
                    SortDescriptor(keyPath: "size", ascending: false)
                ])
                .collectionPublisher
                .subscribe(on: queue)
                .freeze()
                .map { zimFiles in
                    var results = [String: [ZimFile]]()
                    for zimFile in zimFiles {
                        results[zimFile.languageCode, default: []].append(zimFile)
                    }
                    return results
                }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just(([String: [ZimFile]]())) }
                .sink(receiveValue: { zimFiles in
                    withAnimation(self.zimFiles.count > 0 ? .default : nil) {
                        self.languages = zimFiles.keys
                            .compactMap { Language(code: $0) }
                            .sorted(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending })
                        self.zimFiles = zimFiles
                    }
                })
        }
        
        private func downloadFavicon(languageCodes: [String]) {
            do {
                let database = try Realm()
                let zimFiles = database.objects(ZimFile.self)
                    .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                        NSPredicate(format: "categoryRaw = %@", category.rawValue),
                        NSPredicate(format: "languageCode IN %@", languageCodes),
                        NSPredicate(format: "faviconData = nil"),
                        NSPredicate(format: "faviconURL != nil"),
                    ]))
                LibraryService.shared.downloadFavicons(zimFiles: Array(zimFiles))
            } catch {}
        }
    }
}
