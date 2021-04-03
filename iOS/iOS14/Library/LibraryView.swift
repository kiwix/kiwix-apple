//
//  LibraryView.swift
//  Kiwix
//
//  Created by Chris Li on 11/23/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct LibraryView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var viewModel = ViewModel()
    @State private var isShowingZimFileDetailView = false
    var dismiss: (() -> Void) = {}
    
    var body: some View {
        let itemsPerCategory = horizontalSizeClass == .regular ? 6 : 4
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 10) {
                    let header = HStack(alignment: .firstTextBaseline) {
                        Text("On Device").font(.title2).fontWeight(.semibold)
                        Spacer()
                    }
                    Section(header: header, footer: Divider()) {
                        
                    }
                    ForEach(viewModel.result.categories, id: \.rawValue.hash) { category in
                        let header = HStack(alignment: .firstTextBaseline) {
                            Text(category.description).font(.title2).fontWeight(.semibold)
                            Spacer()
                            if viewModel.result.counts[category, default: 0] > itemsPerCategory {
                                let label = HStack(spacing: 4) {
                                    Text("See All")
                                    Image(systemName: "chevron.right")
                                }.font(Font.footnote.weight(.medium))
                                if category == .wikipedia || category == .other {
                                    NavigationLink(destination: LibraryGroupedCategoryView(category: category)) { label }
                                } else {
                                    NavigationLink(destination: LibraryCategoryView(category: category)) { label }
                                }
                            }
                        }
                        let zimFiles = viewModel.result.metaData[category, default: []].prefix(itemsPerCategory)
                        Section(header: header) {
                            ForEach(zimFiles) { zimFile in
                                ZStack{
                                    NavigationLink("", destination: ZimFileDetailView(fileID: zimFile.fileID), isActive: $isShowingZimFileDetailView)
                                    ZimFileCell(zimFile) { isShowingZimFileDetailView = true }
                                }
                            }
                        }
                    }
                }.padding()
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done", action: dismiss)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: Text("gear")) { Image(systemName: "gear") }
                }
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
    struct QueryResult {
        private(set) var categories = [ZimFile.Category]()
        private(set) var metaData = [ZimFile.Category: [ZimFile]]()
        private(set) var counts = [ZimFile.Category: Int]()
        
        init(results: Results<ZimFile>? = nil) {
            guard let results = results else { return }
            for zimFile in results {
                counts[zimFile.category, default: 0] += 1
                guard metaData[zimFile.category, default: []].count < 6 else { continue }
                metaData[zimFile.category, default: []].append(zimFile)
            }
            categories = Array(metaData.keys).sorted()
        }
    }

    class ViewModel: ObservableObject {
        private let queue = DispatchQueue(label: "org.kiwix.libraryUI", qos: .userInitiated)
        private let database = try? Realm(configuration: Realm.defaultConfig)
        private var zimFilesPipeline: AnyCancellable? = nil
        @Published private(set) var result = QueryResult()
        
        init() {
            let predicate = NSPredicate(format: "languageCode == %@", "en")
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
