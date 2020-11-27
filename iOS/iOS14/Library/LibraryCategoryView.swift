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
    @ObservedObject private var viewModel: ViewModel
    @State private var isShowingZimFileDetailView = false
    private let category: ZimFile.Category
    
    init(category: ZimFile.Category) {
        self.category = category
        self.viewModel = ViewModel(category: category)
    }
    
    var body: some View {
        ScrollView{
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 10) {
                ForEach(viewModel.zimFiles) { zimFile in
                    ZStack{
                        NavigationLink("", destination: ZimFileDetailView(id: zimFile.id), isActive: $isShowingZimFileDetailView)
                        ZimFileCell(zimFile) { isShowingZimFileDetailView = true }
                    }
                }
            }.padding()
        }
        .navigationTitle(category.description)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .onAppear { viewModel.load() }
    }
    
    class ViewModel: ObservableObject {
        @Published private(set) var zimFiles = [ZimFile]()
        
        private let category: ZimFile.Category
        private let queue = DispatchQueue(label: "org.kiwix.libraryUI.categoryGeneric")
        private let database = try? Realm(configuration: Realm.defaultConfig)
        private var pipeline: AnyCancellable? = nil
        
        init(category: ZimFile.Category) {
            self.category = category
        }
        
        func load() {
            let predicate = NSPredicate(format: "languageCode == %@ AND categoryRaw == %@", "en", category.rawValue)
            pipeline = database?.objects(ZimFile.self)
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
    }
}

@available(iOS 14.0, *)
struct LibraryGroupedCategoryView: View {
    @ObservedObject private var viewModel: ViewModel
    @State private var isShowingZimFileDetailView = false
    private let category: ZimFile.Category
    
    init(category: ZimFile.Category) {
        self.category = category
        self.viewModel = ViewModel(category: category)
    }
    
    var body: some View {
        ScrollView{
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 10) {
                ForEach(viewModel.result.groups) { group in
                    let header = HStack(alignment: .firstTextBaseline) {
                        Text(group.name).font(.title2).fontWeight(.semibold)
                        Spacer()
                    }
                    Section(header: header) {
                        ForEach(group.zimFiles) { zimFile in
                            ZStack{
                                NavigationLink("", destination: ZimFileDetailView(id: zimFile.id), isActive: $isShowingZimFileDetailView)
                                ZimFileCell(zimFile) { isShowingZimFileDetailView = true }
                            }
                        }
                    }
                }
            }.padding()
        }
        .navigationTitle(category.description)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .onAppear { viewModel.load() }
    }
    
    struct QueryResult {
        private(set) var groups = [Group]()

        init(category: ZimFile.Category, results: Results<ZimFile>? = nil) {
            guard let results = results else { return }
            groups = results.reduce(into: [String: [ZimFile]]()) { result, zimFile in
                result[zimFile.groupID, default: []].append(zimFile)
            }.map { groupID, zimFiles in
                Group(id: groupID, zimFiles: zimFiles)
            }.sorted(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending })
            
            // special sorting logic for wikipedia
            guard category == .wikipedia else { return }
            
            // groups with these suffixes are treated in a special way and will show up first
            let suffixes = ["_all", "_top", "_simple_all", "_100", "_wp1-0.8", "_ray_charles"]
            for suffix in suffixes.reversed() {
                if let index = groups.lastIndex(where: { $0.id.hasSuffix(suffix) }) {
                    groups.insert(groups.remove(at: index), at: 0)
                }
            }
            
            // group with empty string as ID will always be last and named as Other
            if let index = groups.firstIndex(where: { $0.id == "" }) {
                groups.append(groups.remove(at: index))
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
        @Published private(set) var result: QueryResult
        
        private let category: ZimFile.Category
        private let queue = DispatchQueue(label: "org.kiwix.libraryUI.categoryGrouped")
        private let database = try? Realm(configuration: Realm.defaultConfig)
        private var pipeline: AnyCancellable? = nil
        
        init(category: ZimFile.Category) {
            self.result = QueryResult(category: category)
            self.category = category
        }
        
        func load() {
            let predicate = NSPredicate(format: "languageCode == %@ AND categoryRaw == %@", "en", category.rawValue)
            pipeline = database?.objects(ZimFile.self)
                .filter(predicate)
                .sorted(byKeyPath: "size", ascending: false)
                .collectionPublisher
                .subscribe(on: queue)
                .freeze()
                .map { QueryResult(category: self.category, results: $0) }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just(QueryResult(category: self.category)) }
                .assign(to: \.result, on: self)
        }
    }
}
