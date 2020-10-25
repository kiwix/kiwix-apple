//
//  SearchView.swift
//  Kiwix
//
//  Created by Chris Li on 10/25/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct SearchView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var sceneViewModel: SceneViewModel
    @ObservedObject private var viewModel = ViewModel()
    
    var body: some View {
        if viewModel.onDeviceZimFiles.isEmpty {
            Text("No zim files")
        } else {
            if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    ZStack(alignment: .trailing) {
                        searchFilter
                        Divider()
                    }
                    .frame(minWidth: 300, idealWidth: 340, maxWidth: 360)
                    List{}
                }
            } else {
                searchFilter
            }
        }
    }
    
    var searchFilter: some View {
        LazyVStack {
            Section(header: HStack {
                Text("Search Filter").font(.title3).fontWeight(.semibold)
                Spacer()
            }.padding(.leading, 10)) {
                ForEach(viewModel.onDeviceZimFiles, id: \.id) { zimFile in
                    ZimFileCell(zimFile) {
//                        sceneViewModel.loadMainPage(zimFile: zimFile)
                    }
                }
            }
        }
        .modifier(ScrollableModifier())
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

@available(iOS 14.0, *)
private class ViewModel: ObservableObject {
    @Published var onDeviceZimFiles = [ZimFile]()
    private var onDeviceZimFilesPipeline: AnyCancellable? = nil
    
    init() {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue)
            onDeviceZimFilesPipeline = database.objects(ZimFile.self)
                .filter(predicate)
                .sorted(byKeyPath: "size", ascending: false)
                .collectionPublisher
                .subscribe(on: DispatchQueue.main)
                .freeze()
                .map { Array($0) }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just([]) }
                .assign(to: \.onDeviceZimFiles, on: self)
        } catch { }
    }
    
    deinit {
        onDeviceZimFilesPipeline?.cancel()
    }
}
