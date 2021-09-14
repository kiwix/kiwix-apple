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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var viewModel = ViewModel()
    
    var zimFileTapped: ((String) -> Void)?
    var libraryButtonTapped: (() -> Void)?
    var settingsButtonTapped: (() -> Void)?
    
    var body: some View {
        content
        .navigationBarHidden(true)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
    
    var content: some View {
        guard let onDeviceZimFiles = viewModel.onDeviceZimFiles else { return AnyView(EmptyView()) }
        if onDeviceZimFiles.isEmpty {
            return AnyView(welcomeView)
        } else {
            return AnyView(gridView)
        }
    }
    
    var welcomeView: some View {
        VStack(spacing: 15) {
            Spacer()
            VStack(spacing: 0) {
                Image("Kiwix")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 60)
                Text("KIWIX").font(.largeTitle).fontWeight(.bold)
            }
            Divider()
            RoundedRectButton(
                title: "Library",
                iconSystemName: "folder",
                backgroundColor: Color(.systemBlue),
                isCompact: false,
                action: libraryButtonTapped
            ).frame(maxWidth: 450)
            Spacer()
        }.padding()
    }
    
    var gridView: some View {
        ScrollView {
            LazyVStack {
                if horizontalSizeClass == .compact {
                    header
                    Divider().padding(.vertical, 2)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 10) {
                    Section(header: SectionHeader(title: "On Device")) {
                        ForEach(viewModel.onDeviceZimFiles ?? [], id: \.fileID) { zimFile in
//                            ZimFileCell(zimFile) { zimFileTapped?(zimFile.fileID) }
                        }
                    }
                }
            }.padding()
        }
    }
    
    var header: some View {
        HStack {
            Image("Kiwix")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(2)
                .frame(idealHeight: 30)
                .foregroundColor(.black)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.9)))
            Spacer()
            RoundedRectButton(
                title: "Library",
                iconSystemName: "folder",
                backgroundColor: Color(.systemBlue),
                action: libraryButtonTapped
            )
            RoundedRectButton(
                title: "Settings",
                iconSystemName: "gear",
                backgroundColor: Color(.systemGray),
                action: settingsButtonTapped
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
        private var pipeline: AnyCancellable? = nil
        @Published private(set) var onDeviceZimFiles: [ZimFile]?
        
        init() {
            pipeline = Queries.onDeviceZimFiles()?
                .sorted(byKeyPath: "size", ascending: false)
                .collectionPublisher
                .subscribe(on: queue)
                .freeze()
                .map { Array($0) }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just([]) }
                .assign(to: \.onDeviceZimFiles, on: self)
        }
        
        private static func process(results: Results<ZimFile>) -> [String] {
            results.map({$0.fileID})
        }
    }
}

@available(iOS 14.0, *)
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
