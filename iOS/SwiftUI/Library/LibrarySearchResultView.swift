//
//  LibrarySearchResultView.swift
//  Kiwix
//
//  Created by Chris Li on 4/13/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import Defaults
import RealmSwift

struct LibrarySearchResultView: View {
    @ObservedObject private(set) var viewModel = ViewModel()

    var zimFileSelected: (String, String) -> Void = { _, _ in }
    
    var body: some View {
        if !viewModel.searchText.isEmpty, viewModel.zimFiles.isEmpty {
            InfoView(
                imageSystemName: "magnifyingglass",
                title: "No Results",
                help: "There are no zim files matching the search text."
            )
        } else {
            List {
                ForEach(viewModel.zimFiles) { zimFile in
                    Button { zimFileSelected(zimFile.fileID, zimFile.title) } label: {
                        ListRow(
                            title: zimFile.title,
                            detail: zimFile.description,
                            faviconData: viewModel.favicons[zimFile.fileID],
                            accessories: zimFile.isOnDevice ? [.onDevice, .disclosureIndicator] :
                                [.disclosureIndicator]
                        )
                    }
                }
            }.gesture(DragGesture().onChanged { gesture in
                guard gesture.predictedEndLocation.y < gesture.startLocation.y else { return }
                UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.endEditing(false)
            })
        }
    }
    
    struct ZimFileData: Identifiable {
        var id: String { fileID }
        let fileID: String
        let title: String
        let description: String
        let isOnDevice: Bool
    }

    class ViewModel: ObservableObject {
        @Published private(set) var searchText = ""
        @Published private(set) var zimFiles = [ZimFileData]()
        @Published private(set) var favicons = [String: Data]()
        
        private let database = try? Realm()
        private let queue = DispatchQueue(label: "org.kiwix.library.search", qos: .userInitiated)
        private var collectionSubscriber: AnyCancellable?
        private var faviconSubscriber: AnyCancellable?
        
        func update(_ searchText: String) {
            self.searchText = searchText
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "title CONTAINS[cd] %@", searchText),
                NSPredicate(format: "languageCode IN %@", Defaults[.libraryLanguageCodes])
            ])
            collectionSubscriber = database?.objects(ZimFile.self)
                .filter(predicate)
                .sorted(by: [
                    SortDescriptor(keyPath: "title", ascending: true),
                    SortDescriptor(keyPath: "size", ascending: false)
                ])
                .collectionPublisher(keyPaths: ["fileID"])
                .subscribe(on: queue)
                .freeze()
                .map { zimFiles in
                    zimFiles.forEach { zimFile in
                        guard zimFile.faviconData == nil, zimFile.faviconURL != nil else { return }
                        FaviconDownloadService.shared.download(zimFile: zimFile)
                    }
                    return zimFiles.map { zimFile in
                        ZimFileData(
                            fileID: zimFile.fileID,
                            title: zimFile.title,
                            description: zimFile.description,
                            isOnDevice: zimFile.state == .onDevice
                        )
                    }
                }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just(([ZimFileData]())) }
                .sink(receiveValue: { zimFiles in
                    self.zimFiles = zimFiles
                })
            faviconSubscriber = database?.objects(ZimFile.self)
                .filter(predicate)
                .collectionPublisher(keyPaths: ["fileID", "faviconData"])
                .subscribe(on: queue)
                .freeze()
                .throttle(for: 0.2, scheduler: queue, latest: true)
                .map { zimFiles in
                    Dictionary(
                        zimFiles.map { ($0.fileID, $0.faviconData) }, uniquingKeysWith: { data, _ in data }
                    ).compactMapValues({$0})
                }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just([String: Data]()) }
                .sink(receiveValue: { favicons in
                    self.favicons.merge(favicons, uniquingKeysWith: { $1 })
                })
        }
    }
}
