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

import Defaults

struct Search: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    @StateObject private var viewModel = SearchViewModel()
    @Default(.recentSearchTexts) var recentSearchTexts
    
    var body: some View {
        SearchField(searchText: $viewModel.searchText).padding(.horizontal, 6)
        HStack(alignment: .center) {
            Button("Scope") { }
            Spacer()
            if viewModel.inProgress {
                ProgressView()
                    .scaleEffect(0.5, anchor: .leading)
                    .frame(width: 10, height: 10)
            }
        }.padding(.horizontal, 6)
        Divider()
        if viewModel.searchText.isEmpty {
            List {
                Text("Recent search text 1")
                Text("Recent search text 2")
                Text("Recent search text 3")
            }
        } else if !viewModel.results.isEmpty, !viewModel.inProgress {
            List(selection: $sceneViewModel.url) {
                ForEach(viewModel.results, id: \.url) { result in
                    Text(result.title)
                }
            }
        } else if viewModel.results.isEmpty, !viewModel.inProgress {
            List { Text("No result") }
        } else {
            List {}
        }
    }
}

private class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var inProgress = false
    @Published var results = [SearchResult]()
    
    private var searchSubscriber: AnyCancellable?
    private var inProgressSubscriber: AnyCancellable?
    private let queue = OperationQueue()
    
    init() {
        queue.maxConcurrentOperationCount = 1
        searchSubscriber = (try? Realm())?.objects(ZimFile.self)
            .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
                NSPredicate(format: "includedInSearch == true"),
            ]))
            .collectionPublisher
            .freeze()
            .map { Array($0.map({ $0.fileID })) }
            .catch { _ in Just([]) }
            .combineLatest($searchText)
            .debounce(for: 0.2, scheduler: queue, options: nil)
            .receive(on: DispatchQueue.main, options: nil)
            .sink { zimFileIDs, searchText in
                self.updateSearchResults(searchText, Set(zimFileIDs))
            }
        inProgressSubscriber = $searchText.sink { searchText in self.inProgress = !searchText.isEmpty }
    }
    
    private func updateSearchResults(_ searchText: String, _ zimFileIDs: Set<String>) {
        queue.cancelAllOperations()
        let operation = SearchOperation(searchText: searchText, zimFileIDs: zimFileIDs)
        operation.completionBlock = { [unowned self] in
            guard !operation.isCancelled else { return }
            DispatchQueue.main.sync {
                self.results = operation.results
                self.inProgress = false
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
