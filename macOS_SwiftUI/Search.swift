//
//  Search.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 11/6/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

struct Search: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        SearchField(searchText: $viewModel.searchText).padding(.horizontal, 6)
        Button("Scope") { }
        Divider()
        List {
            if viewModel.searchText.isEmpty {
                EmptyView()
            } else {
                Text("result 1")
                Text("result 2")
                Text("result 3")
            }
        }
    }
}

private class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var inProgress = false
    @Published var results = [SearchResult]()
    
    private var searchSubscriber: AnyCancellable?
    private let queue = OperationQueue()
    
    init() {
        queue.maxConcurrentOperationCount = 1
        do {
            let database = try Realm()
            searchSubscriber = database.objects(ZimFile.self)
                .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
                    NSPredicate(format: "includedInSearch == true"),
                ]))
                .collectionPublisher
                .freeze()
                .map { Array($0.map({ $0.fileID })) }
                .catch { _ in Just([]) }
                .combineLatest($searchText)
                .sink { zimFileIDs, searchText in
                    self.updateSearchResults(searchText, Set(zimFileIDs))
                }
        } catch {}
    }
    
    private func updateSearchResults(_ searchText: String, _ zimFileIDs: Set<String>) {
        self.searchText = searchText
        inProgress = true
        
        queue.cancelAllOperations()
        let operation = SearchOperation(searchText: searchText, zimFileIDs: zimFileIDs)
        operation.completionBlock = { [unowned self] in
            guard !operation.isCancelled else { return }
            DispatchQueue.main.sync {
                self.results = operation.results
                self.inProgress = self.queue.operationCount > 0
            }
        }
        queue.addOperation(operation)
    }
}

private struct SearchField: NSViewRepresentable {
    @Binding var searchText: String
    
    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.delegate = context.coordinator
        return searchField
    }
    
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = searchText
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSSearchFieldDelegate {
        private var searchField: SearchField
        
        init(_ searchField: SearchField) {
            self.searchField = searchField
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let searchField = obj.object as? NSSearchField else { return }
            self.searchField.searchText = searchField.stringValue
        }
    }
}
