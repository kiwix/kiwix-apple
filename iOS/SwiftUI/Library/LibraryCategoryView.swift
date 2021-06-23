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

/// List of zim files under a single category,
@available(iOS 14.0, *)
struct LibraryCategoryView: View {
    @StateObject private var viewModel: ViewModel
    
    let category: ZimFile.Category
    var zimFileTapped: (String, String) -> Void = { _, _ in }
    
    init(category: ZimFile.Category) {
        self.category = category
        self._viewModel = StateObject(wrappedValue: ViewModel(category: category))
    }
    
    var body: some View {
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
    
    class ViewModel: NSObject, ObservableObject, URLSessionDelegate, URLSessionDataDelegate {
        @Published private(set) var languages: [Language] = []
        @Published private(set) var zimFiles = [String: [ZimFile]]()
        private var favicon = [String: Data]()
        
        let category: ZimFile.Category
        private let queue = DispatchQueue(label: "org.kiwix.library.category", qos: .userInitiated)
        private var defaultsSubscriber: AnyCancellable?
        private var collectionSubscriber: AnyCancellable?
        
        init(category: ZimFile.Category) {
            self.category = category
            super.init()
            defaultsSubscriber = UserDefaults.standard.publisher(for: \.libraryLanguageCodes)
                .sink(receiveValue: { languageCodes in
                    self.loadData(languageCodes: languageCodes)
                    self.downloadFavicon(languageCodes: languageCodes)
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
                        guard zimFile.faviconData == nil,
                              let urlString = zimFile.faviconURL,
                              let url = URL(string: urlString) else { continue }
//                        LibraryService.shared.downloadFavicon(zimFileID: zimFile.fileID, url: url)
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
            let operationQueue = OperationQueue()
            operationQueue.underlyingQueue = queue
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: operationQueue)
            
            let database = try? Realm()
            database?.objects(ZimFile.self)
                .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "categoryRaw = %@", category.rawValue),
                    NSPredicate(format: "languageCode IN %@", languageCodes),
                    NSPredicate(format: "faviconData = nil"),
                    NSPredicate(format: "faviconURL != nil"),
                ]))
                .forEach { zimFile in
                    guard let urlString = zimFile.faviconURL, let url = URL(string: urlString) else { return }
                    let zimFileID = zimFile.fileID
                    favicon[zimFileID] = Data()
                    let task = session.dataTask(with: url) { data, response, error in
                        self.favicon[zimFileID] = data
                        self.flushFavicon(inBatch: true)
                    }
                    task.resume()
                }
            session.finishTasksAndInvalidate()
        }
        
        private func flushFavicon(inBatch: Bool) {
            let favicon: [String: Data] = {
                if inBatch {
                    let batch = self.favicon.filter { $1.count > 0 }
                    return batch.count >= 5 ? batch : [:]
                } else {
                    return self.favicon
                }
            }()
            guard !favicon.isEmpty else { return }
            print(favicon)
            
            do {
                let database = try Realm()
                try database.write {
                    for (zimFileID, data) in favicon {
                        let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID)
                        zimFile?.faviconData = data
                    }
                }
            } catch {}
        }
        
        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            flushFavicon(inBatch: false)
        }
    }
}
