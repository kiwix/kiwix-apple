//
//  LibraryCategoryView.swift
//  Kiwix
//
//  Created by Chris Li on 11/26/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct LibraryCategoryView: View {
    let category: ZimFile.Category
    @ObservedObject private var viewModel: ViewModel
    
    init(category: ZimFile.Category) {
        self.category = category
        self.viewModel = ViewModel(category: category)
    }
    
    var body: some View {
        ScrollView{
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 10) {
                ForEach(viewModel.zimFiles) { zimFile in
                    ZimFileCell(zimFile) {}
                }
            }.padding()
        }
        .navigationTitle(category.description)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
    
    class ViewModel: ObservableObject {
        let category: ZimFile.Category
        @Published private(set) var zimFiles = [ZimFile]()
        
        private let queue = DispatchQueue(label: "org.kiwix.libraryUI.categoryGeneric", qos: .userInitiated)
        private let database = try? Realm(configuration: Realm.defaultConfig)
        private var zimFilesPipeline: AnyCancellable? = nil
        
        init(category: ZimFile.Category) {
            self.category = category
            let predicate = NSPredicate(format: "languageCode == %@ AND categoryRaw == %@", "en", category.rawValue)
            zimFilesPipeline = database?.objects(ZimFile.self)
                .filter(predicate)
                .sorted(byKeyPath: "title", ascending: true)
                .collectionPublisher
                .subscribe(on: queue)
                .freeze()
                .map { Array($0) }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just([]) }
                .assign(to: \.zimFiles, on: self)
        }
        
        deinit {
            zimFilesPipeline?.cancel()
        }
    }
}

@available(iOS 14.0, *)
struct LibraryWikipediaCategoryView: View {
    @ObservedObject private var viewModel = ViewModel()
    
    var body: some View {
        ScrollView{
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 10) {
                ForEach(viewModel.result.groups) { group in
                    let header = HStack(alignment: .firstTextBaseline) {
                        Text(group.name).font(.title2).fontWeight(.bold)
                        Spacer()
                    }
                    Section(header: header) {
                        ForEach(group.zimFiles) { zimFile in
                            ZimFileCell(zimFile) {}
                        }
                    }
                }
            }.padding()
        }
        .navigationTitle(ZimFile.Category.wikipedia.description)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
    
    struct QueryResult {
        private(set) var groups = [Group]()

        init(results: Results<ZimFile>? = nil) {
            guard let results = results else { return }
            groups = results.reduce(into: [String: [ZimFile]]()) { result, zimFile in
                result[zimFile.groupID, default: []].append(zimFile)
            }.map { groupID, zimFiles in
                Group(id: groupID, zimFiles: zimFiles)
            }.sorted(by: { $0.name < $1.name })
            
            if let otherIndex = self.groups.firstIndex(where: { $0.id == "" }) {
                let otherGroup = self.groups.remove(at: otherIndex)
                self.groups.append(otherGroup)
            }
        }
    }
    
    struct Group: Identifiable {
        let id: String
        let name: String
        let zimFiles: [ZimFile]
        
        init(id: String, zimFiles: [ZimFile]) {
            self.id = id
            if id.isEmpty {
                self.name = "Other"
            } else {
                self.name = zimFiles.first?.title ?? id
            }
            self.zimFiles = zimFiles
        }
    }
    
    class ViewModel: ObservableObject {
        private let queue = DispatchQueue(label: "org.kiwix.libraryUI.categoryGrouped", qos: .userInitiated)
        private let database = try? Realm(configuration: Realm.defaultConfig)
        private var zimFilesPipeline: AnyCancellable? = nil
        @Published private(set) var result = QueryResult()
        
        init() {
            let predicate = NSPredicate(format: "languageCode == %@ AND categoryRaw == %@", "en", ZimFile.Category.wikipedia.rawValue)
            zimFilesPipeline = database?.objects(ZimFile.self)
                .filter(predicate)
                .sorted(byKeyPath: "size", ascending: false)
                .collectionPublisher
                .subscribe(on: queue)
                .freeze()
                .map { QueryResult(results: $0) }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just(QueryResult()) }
                .assign(to: \.result, on: self)
        }
        
        deinit {
            zimFilesPipeline?.cancel()
        }
    }
}
