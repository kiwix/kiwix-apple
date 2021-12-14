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
    @Binding var url: URL?
    @ObservedResults(
        ZimFile.self,
        filter: NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
        sortDescriptor: SortDescriptor(keyPath: "size", ascending: false)
    ) private var zimFiles
    
    
    var body: some View {
        VSplitView {
            VStack {
                SearchField(searchText: $viewModel.searchText).padding(.horizontal, 8)
                if viewModel.searchText.isEmpty, !recentSearchTexts.isEmpty {
                    List {
                        Section("Recent") {
                            ForEach(recentSearchTexts, id: \.hash) { searchText in
                                Text(searchText)
                            }
                        }
                    }
                } else if !viewModel.searchText.isEmpty, !viewModel.results.isEmpty {
                    List(selection: $url) {
                        ForEach(viewModel.results, id: \.url) { result in
                            Text(result.title)
                        }
                    }
                } else {
                    List {}
                }
            }.frame(minHeight: 100, idealHeight: 300)
            VStack(spacing: 0) {
                HStack {
                    Text("Include in Search").foregroundColor(.primary)
                    Spacer()
                    if zimFiles.map {$0.includedInSearch }.reduce(true) { $0 && $1 } {
                        Button("None") {

                        }
                    } else {
                        Button("All") {

                        }
                    }
                }.padding(.vertical, 5).padding(.leading, 16).padding(.trailing, 10)
                Divider()
                List {
                    ForEach(zimFiles, id: \.fileID) { zimFile in
                        Toggle(zimFile.title, isOn: zimFile.bind(\.includedInSearch))
                    }
                }
            }.frame(minHeight: 100, idealHeight: 150)
        }
        
//        VStack(spacing: 0) {
//            SearchField(searchText: $viewModel.searchText).padding(.horizontal, 8)
//
//
//            if viewModel.searchText.isEmpty {
//                List {
//                    Section {
//                        ForEach(zimFiles, id: \.fileID) { zimFile in
//                            Toggle(zimFile.title, isOn: zimFile.bind(\.includedInSearch))
//                        }
//                    } header: {
//                        HStack {
//                            Text("Include in Search").foregroundColor(.primary)
//                            Spacer()
//                            if zimFiles.map {$0.includedInSearch }.reduce(true) { $0 && $1 } {
//                                Button("None") {
//
//                                }
//                            } else {
//                                Button("All") {
//
//                                }
//                            }
//                        }.padding(.trailing, 8).padding(.top, 8)
//                    }.collapsible(false)
//                }.safeAreaInset(edge: .bottom) {
//                    List {
//                        Section {
//                            ForEach(zimFiles, id: \.fileID) { zimFile in
//                                Toggle(zimFile.title, isOn: zimFile.bind(\.includedInSearch))
//                            }
//                        } header: {
//                            HStack {
//                                Text("Include in Search").foregroundColor(.primary)
//                                Spacer()
//                                if zimFiles.map {$0.includedInSearch }.reduce(true) { $0 && $1 } {
//                                    Button("None") {
//
//                                    }
//                                } else {
//                                    Button("All") {
//
//                                    }
//                                }
//                            }.padding(.trailing, 8).padding(.top, 8)
//                        }.collapsible(false)
//                    }
//                }
//            } else {
//                List(selection: $url) {
//                    ForEach(viewModel.results, id: \.url) { result in
//                        Text(result.title)
//                    }
//                }
//            }
//        }
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
