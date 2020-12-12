//
//  HomeView.swift
//  Kiwix
//
//  Created by Chris Li on 12/12/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct HomeView: View {
    @ObservedObject private var viewModel = ViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack {
                header
                Divider().padding(.vertical, 2)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 10) {
                    Section(header: SectionHeader(title: "On Device")) {
                        ForEach(viewModel.zimFileMeta, id: \.hash) { zimFile in
                            Text(zimFile)
                        }
                    }
                }
            }.padding()
        }
        .navigationBarHidden(true)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
    
    var header: some View {
        HStack {
            Image("Kiwix")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(2)
                .frame(idealHeight: 40)
                .foregroundColor(.black)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.9)))
            Spacer()
            RoundedRectButton(
                title: "Library",
                iconSystemName: "folder",
                backgroundColor: Color(.systemBlue),
                action: nil
            )
            RoundedRectButton(
                title: "Settings",
                iconSystemName: "gear",
                backgroundColor: Color(.systemGray),
                action: nil
            )
        }
    }
    
    struct SectionHeader: View {
        let title: String
        
        var body: some View {
            HStack {
                Text(title).font(.title2).fontWeight(.bold)
                Spacer()
            }
        }
    }
    
    class ViewModel: ObservableObject {
        private let queue = DispatchQueue(label: "org.kiwix.homeViewUI", qos: .userInitiated)
        private let database = try? Realm(configuration: Realm.defaultConfig)
        private var pipeline: AnyCancellable? = nil
        @Published private(set) var zimFileMeta = [String]()
        
        init() {
            let predicate = NSPredicate(format: "languageCode == %@", "en")
            pipeline = database?.objects(ZimFile.self)
                .filter(predicate)
                .sorted(byKeyPath: "size", ascending: false)
                .collectionPublisher
                .subscribe(on: queue)
                .freeze()
                .map { ViewModel.process(results: $0) }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just([]) }
                .assign(to: \.zimFileMeta, on: self)
        }
        
        private static func process(results: Results<ZimFile>) -> [String] {
            results.map({$0.id})
        }
    }
}

@available(iOS 14.0, *)
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
