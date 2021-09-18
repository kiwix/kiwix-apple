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
struct LibraryCategoryView: View {
    @ObservedObject private var viewModel: ViewModel
    @Default(.libraryLastRefresh) private var libraryLastRefresh
    
    let category: ZimFile.Category
    var zimFileTapped: (String, String) -> Void = { _, _ in }
    
    init(category: ZimFile.Category) {
        self.category = category
        self._viewModel = ObservedObject(wrappedValue: ViewModel(category: category))
    }
    
    var body: some View {
        if libraryLastRefresh == nil {
            refreshNeeded
        } else if viewModel.isInitialLoading {
            EmptyView()
        } else if viewModel.sections.isEmpty {
            empty
        } else {
            list
        }
    }
    
    var refreshNeeded: some View {
        InfoView(
            imageSystemName: {
                if #available(iOS 14.0, *) {
                    return "text.book.closed"
                } else {
                    return "book"
                }
            }(),
            title: "No Zim Files",
            help: "Download online catalog to see zim files under this category."
        )
    }
    
    var empty: some View {
        InfoView(
            imageSystemName: {
                if #available(iOS 14.0, *) {
                    return "text.book.closed"
                } else {
                    return "book"
                }
            }(),
            title: "No Zim Files",
            help: "Enable some other languages to see zim files under this category."
        )
    }
    
    var list: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section(header: viewModel.sections.count > 1 ? Text(section.languageName) : nil) {
                    ForEach(section.zimFiles) { zimFile in
                        Button { zimFileTapped(zimFile.fileID, zimFile.title) } label: {
                            ListRow(
                                title: zimFile.title,
                                detail: zimFile.description,
                                faviconData: zimFile.faviconData,
                                accessories: zimFile.isOnDevice ? [.onDevice, .disclosureIndicator] :
                                    [.disclosureIndicator]
                            )
                        }
                    }
                }
            }
        }.listStyle(PlainListStyle())
    }
    
    struct ZimFileData: Identifiable {
        var id: String { fileID }
        let fileID: String
        let title: String
        let description: String
        let isOnDevice: Bool
        var faviconData: Data?
    }
    
    struct SectionData: Identifiable {
        var id: String { languageCode }
        let languageCode: String
        let languageName: String
        let zimFiles: [ZimFileData]
        
        init?(languageCode: String, zimFiles: [ZimFileData]) {
            guard let languageName = Locale.current.localizedString(forLanguageCode: languageCode) else { return nil }
            self.languageCode = languageCode
            self.languageName = languageName
            self.zimFiles = zimFiles
        }
    }
    
    class ViewModel: ObservableObject {
        @Published private(set) var isInitialLoading = true
        @Published private(set) var sections = [SectionData]()
        
        private let category: ZimFile.Category
        private let database = try? Realm()
        private let queue = DispatchQueue(label: "org.kiwix.library.category", qos: .userInitiated)
        private var languageCodeObserver: Defaults.Observation?
        private var collectionSubscriber: AnyCancellable?
        
        init(category: ZimFile.Category) {
            self.category = category
            languageCodeObserver = Defaults.observe(.libraryLanguageCodes) { languageCodes in
                self.loadData(languageCodes: languageCodes.newValue)
//                self.database?.objects(ZimFile.self)
//                    .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
//                        NSPredicate(format: "categoryRaw = %@", category.rawValue),
//                        NSPredicate(format: "languageCode IN %@", languageCodes.newValue),
//                        NSPredicate(format: "faviconData = nil"),
//                        NSPredicate(format: "faviconURL != nil"),
//                    ]))
//                    .forEach { FaviconDownloadService.shared.download(zimFile: $0) }
            }
        }
        
        private func loadData(languageCodes: [String]) {
            collectionSubscriber = database?.objects(ZimFile.self)
                .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "categoryRaw = %@", category.rawValue),
                    NSPredicate(format: "languageCode IN %@", languageCodes)
                ]))
                .sorted(by: [
                    SortDescriptor(keyPath: "title", ascending: true),
                    SortDescriptor(keyPath: "size", ascending: false)
                ])
                .collectionPublisher(keyPaths: ["fileID", "faviconData"])
                .subscribe(on: queue)
                .freeze()
                .throttle(for: 0.2, scheduler: queue, latest: true)
                .map { zimFiles in
                    var results = [String: [ZimFileData]]()
                    for zimFile in zimFiles {
                        let data = ZimFileData(
                            fileID: zimFile.fileID,
                            title: zimFile.title,
                            description: zimFile.description,
                            isOnDevice: zimFile.state == .onDevice,
                            faviconData: zimFile.faviconData
                        )
                        results[zimFile.languageCode, default: []].append(data)
                    }
                    return results.compactMap { SectionData(languageCode: $0, zimFiles: $1) }
                    .sorted(by: { $0.languageName.caseInsensitiveCompare($1.languageName) == .orderedAscending })
                }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just([SectionData]()) }
                .sink(receiveValue: { sections in
                    withAnimation(self.sections.count > 0 ? .default : nil) {
                        self.isInitialLoading = false
                        self.sections = sections
                    }
                })
        }
    }
}
