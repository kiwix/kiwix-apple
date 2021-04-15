//
//  LibrarySearchResultView.swift
//  Kiwix
//
//  Created by Chris Li on 4/13/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct LibrarySearchResultView: View {
    @ObservedObject var viewModel = ViewModel()
    
    var zimFileSelected: (String, String) -> Void = { _, _ in }
    
    var body: some View {
        HStack {
            if viewModel.results.count > 0 {
                List {
                    ForEach(viewModel.results) { zimFile in
                        Button(action: { zimFileSelected(zimFile.fileID, zimFile.title) }, label: {
                            ZimFileCell(zimFile)
                        })
                    }
                }
            } else if viewModel.searchText.value.count > 0 {
                Text("No Results")
            }
        }
    }
    
    class ViewModel: ObservableObject {
        @Published private(set) var results: [ZimFile] = []
        
        var searchText = CurrentValueSubject<String, Never>("")
        private var searchTextSubscriber: AnyCancellable?
        
        init() {
            searchTextSubscriber = searchText
                .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
                .compactMap({$0})
                .sink { [unowned self] searchText in self.update(searchText) }
        }
        
        private func update(_ searchText: String) {
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let database = try Realm()
                    let zimFiles = database.objects(ZimFile.self)
                        .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                            NSPredicate(format: "title CONTAINS[cd] %@", searchText),
                            NSPredicate(format: "languageCode IN %@", UserDefaults.standard.libraryLanguageCodes),
                        ])).freeze()
                    DispatchQueue.main.async {
                        self.results = Array(zimFiles)
                    }
                } catch { self.results = [] }
            }
        }
    }
}
