//
//  Search.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 11/6/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import SwiftUI

import Defaults

/// Search interface in the sidebar.
struct Search: View {
    @Binding var url: URL?
    @State private var selectedSearchText: String?
    @StateObject private var viewModel = ViewModel()
    @Default(.recentSearchTexts) private var recentSearchTexts: [String]
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: FetchedResults<ZimFile>
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "fileURLBookmark != nil AND includedInSearch == true")
    ) private var includedInSearchZimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        SearchField(searchText: $viewModel.searchText).padding(.horizontal, 10).padding(.vertical, 6)
        searchResults
        searchFilter
    }
    
    @ViewBuilder
    var searchResults: some View {
        if viewModel.searchText.isEmpty, !recentSearchTexts.isEmpty {
            List(recentSearchTexts, id: \.self, selection: $selectedSearchText) { searchText in
                Text(searchText)
            }.onChange(of: selectedSearchText) { self.updateCurrentSearchText($0) }
        } else if !viewModel.searchText.isEmpty, !viewModel.results.isEmpty {
            List(viewModel.results, id: \.url, selection: $url) { searchResult in
                Text(searchResult.title)
            }.onChange(of: url) { _ in self.updateRecentSearchTexts(viewModel.searchText) }
        } else if !viewModel.searchText.isEmpty, viewModel.results.isEmpty, !viewModel.inProgress {
            List { Text("No Result") }
        } else {
            List { }
        }
    }
    
    var searchFilter: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text("Include in Search").fontWeight(.medium)
                Spacer()
                if zimFiles.map {$0.includedInSearch }.reduce(true) { $0 && $1 } {
                    Button { selectNoZimFiles() } label: {
                        Text("None").font(.caption).fontWeight(.medium)
                    }
                } else {
                    Button { selectAllZimFiles() } label: {
                        Text("All").font(.caption).fontWeight(.medium)
                    }
                }
            }.padding(.vertical, 5).padding(.leading, 16).padding(.trailing, 10).background(.regularMaterial)
            Divider()
            List {
                ForEach(zimFiles, id: \.fileID) { zimFile in
                    Toggle(zimFile.name, isOn: Binding<Bool>(get: {
                        zimFile.includedInSearch
                    }, set: {
                        zimFile.includedInSearch = $0
                        try? managedObjectContext.save()
                    }))
                }
            }
        }.frame(height: 180)
    }
    
    private func updateCurrentSearchText(_ searchText: String?) {
        guard let searchText = searchText else { return }
        viewModel.searchText = searchText
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectedSearchText = nil
        }
    }
    
    private func updateRecentSearchTexts(_ searchText: String) {
        guard !searchText.isEmpty else { return }
        var recentSearchTexts = self.recentSearchTexts
        recentSearchTexts.removeAll { $0 == searchText }
        recentSearchTexts.insert(searchText, at: 0)
        self.recentSearchTexts = recentSearchTexts
    }
    
    private func selectAllZimFiles() {
        let request = ZimFile.fetchRequest()
        try? managedObjectContext.fetch(request).forEach { zimFile in
            zimFile.includedInSearch = true
        }
        try? managedObjectContext.save()
    }
    
    private func selectNoZimFiles() {
        let request = ZimFile.fetchRequest()
        try? managedObjectContext.fetch(request).forEach { zimFile in
            zimFile.includedInSearch = false
        }
        try? managedObjectContext.save()
    }
}

private class ViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var inProgress = false
    @Published var results = [SearchResult]()
    
    private var searchSubscriber: AnyCancellable?
    private var searchTextSubscriber: AnyCancellable?
    private let queue = OperationQueue()
    
    init() {
        queue.maxConcurrentOperationCount = 1
        
//        searchSubscriber = (try? Realm())?.objects(ZimFile.self)
//            .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
//                NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
//                NSPredicate(format: "includedInSearch == true"),
//            ]))
//            .collectionPublisher
//            .freeze()
//            .map { Array($0.map({ $0.fileID })) }
//            .catch { _ in Just([]) }
//            .combineLatest($searchText)
//            .debounce(for: 0.2, scheduler: queue, options: nil)
//            .receive(on: DispatchQueue.main, options: nil)
//            .sink { zimFileIDs, searchText in
//                self.updateSearchResults(searchText, Set(zimFileIDs))
//            }
        searchTextSubscriber = $searchText.sink { searchText in self.inProgress = !searchText.isEmpty }
    }
    
    private func updateSearchResults(_ searchText: String, _ zimFileIDs: Set<String>) {
        queue.cancelAllOperations()
        let operation = SearchOperation(searchText: searchText, zimFileIDs: zimFileIDs)
        operation.completionBlock = { [unowned self] in
            guard !operation.isCancelled else { return }
            DispatchQueue.main.sync {
//                self.results = operation.results
                self.inProgress = false
            }
        }
        queue.addOperation(operation)
    }
}
