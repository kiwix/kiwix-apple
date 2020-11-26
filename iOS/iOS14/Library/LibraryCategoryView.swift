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
            }
        }.navigationTitle(category.description)
    }
    
    class ViewModel: ObservableObject {
        let category: ZimFile.Category
        @Published private(set) var zimFiles = [ZimFile]()
        
        private let queue = DispatchQueue(label: "org.kiwix.libraryUI", qos: .userInitiated)
        private let database = try? Realm(configuration: Realm.defaultConfig)
        private var zimFilesPipeline: AnyCancellable? = nil
        
        init(category: ZimFile.Category) {
            self.category = category
            let predicate = NSPredicate(format: "languageCode == %@ AND categoryRaw == %@", "en", category.rawValue)
            zimFilesPipeline = database?.objects(ZimFile.self)
                .filter(predicate)
                .sorted(byKeyPath: "size", ascending: false)
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
