//
//  LibraryCategoryView.swift
//  Kiwix
//
//  Created by Chris Li on 4/4/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct LibraryCategoryView: View {
    @StateObject private var viewModel: ViewModel
    @State private var showingPopover = false
    
    let category: ZimFile.Category
    
    init(category: ZimFile.Category) {
        self.category = category
        self._viewModel = StateObject(wrappedValue: ViewModel(category: category))
    }
    
    var body: some View {
        List {
            ForEach(viewModel.languages) { language in
                Section(header: Text(language.name)) {
                    ForEach(viewModel.zimFiles[language.code, default: []]) { zimFileViewModel in
                        ZimFileView(zimFileViewModel)
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
        @Published var sortingMode: LibraryCategorySortingMode {
            didSet {
                UserDefaults.standard.set(sortingMode.rawValue, forKey: "libraryCategorySortingMode")
                sortingModePublisher.send(sortingMode)
            }
        }
        @Published private(set) var languages: [Language] = []
        @Published private(set) var zimFiles = [String: [ZimFileView.ViewModel]]()
        
        let category: ZimFile.Category
        private let queue = DispatchQueue(label: "org.kiwix.libraryUI.category", qos: .userInitiated)
        private let sortingModePublisher: CurrentValueSubject<LibraryCategorySortingMode, Never>
        private var defaultsSubscriber: AnyCancellable?
        private var collectionSubscriber: AnyCancellable?
        
        init(category: ZimFile.Category) {
            self.category = category
            
            let sortingModeRawValue = UserDefaults.standard.string(forKey: "libraryCategorySortingMode") ?? ""
            let sortingMode = LibraryCategorySortingMode(rawValue: sortingModeRawValue) ?? .alphabetical
            self.sortingMode = sortingMode
            self.sortingModePublisher = CurrentValueSubject(sortingMode)
            
            defaultsSubscriber = Publishers.CombineLatest(
                UserDefaults.standard.publisher(for: \.libraryLanguageCodes), sortingModePublisher
            ).sink(receiveValue: { (languageCodes, sortingMode) in
                self.loadData(languageCodes: languageCodes, sortingMode: sortingMode)
            })
        }
        
        private func loadData(languageCodes: [String], sortingMode: LibraryCategorySortingMode) {
            do {
                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "categoryRaw = %@", category.rawValue),
                    NSPredicate(format: "languageCode IN %@", languageCodes),
                ])
                let database = try Realm()
                collectionSubscriber = database.objects(ZimFile.self)
                    .filter(predicate)
                    .sorted(byKeyPath: "title")
                    .collectionPublisher
                    .subscribe(on: queue)
                    .freeze()
                    .map { zimFiles in
                        var results = [String: [ZimFileView.ViewModel]]()
                        for zimFile in zimFiles {
                            results[zimFile.languageCode, default: []].append(ZimFileView.ViewModel(zimFile))
                        }
                        return results
                    }
                    .receive(on: DispatchQueue.main)
                    .catch { _ in Just([String: [ZimFileView.ViewModel]]()) }
                    .sink(receiveValue: { zimFiles in
                        withAnimation(self.zimFiles.count > 0 ? .default : nil) {
                            self.languages = zimFiles.keys
                                .compactMap { Language(code: $0) }
                                .sorted(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending })
                            self.zimFiles = zimFiles
                        }
                    })
            } catch {}
        }
    }
}
