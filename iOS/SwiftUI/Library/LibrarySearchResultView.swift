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
        List {
            ForEach(viewModel.zimFiles) { zimFile in
                Button(action: { zimFileSelected(zimFile.fileID, zimFile.title) }, label: {
                    ZimFileCell(zimFile)
                })
            }
        }.gesture(DragGesture().onChanged { gesture in
            guard gesture.predictedEndLocation.y < gesture.startLocation.y else { return }
            UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.endEditing(false)
        })
    }

    class ViewModel: ObservableObject {
        @Published private(set) var zimFiles = [ZimFile]()
        
        private let database = try? Realm()
        private let queue = DispatchQueue(label: "org.kiwix.library.category", qos: .userInitiated)
        private var collectionSubscriber: AnyCancellable?
        
        func update(_ searchText: String) {
            collectionSubscriber = database?.objects(ZimFile.self)
                .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "title CONTAINS[cd] %@", searchText),
                    NSPredicate(format: "languageCode IN %@", Defaults[.libraryLanguageCodes])
                ]))
                .sorted(by: [
                    SortDescriptor(keyPath: "title", ascending: true),
                    SortDescriptor(keyPath: "size", ascending: false)
                ])
                .collectionPublisher
                .subscribe(on: queue)
                .freeze()
                .throttle(for: 0.2, scheduler: queue, latest: true)
                .map { Array($0) }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just(([ZimFile]())) }
                .sink(receiveValue: { zimFiles in
                    self.zimFiles = zimFiles
                })
            database?.objects(ZimFile.self)
                .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "title CONTAINS[cd] %@", searchText),
                    NSPredicate(format: "languageCode IN %@", Defaults[.libraryLanguageCodes]),
                    NSPredicate(format: "faviconData = nil"),
                    NSPredicate(format: "faviconURL != nil"),
                ]))
                .forEach { FaviconDownloadService.shared.download(zimFile: $0) }
        }
    }
}
