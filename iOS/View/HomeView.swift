//
//  HomeView.swift
//  Kiwix
//
//  Created by Chris Li on 9/24/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//


import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var viewModel = ViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack {
                    HStack {
                        Image("Kiwix")
                            .interpolation(.high)
                            .resizable()
                            .frame(width: 42, height: 42)
                        Spacer()
                        Button(action: {
                            print("Library tapped!")
                        }) {
                            Label(
                                title: { Text("Library").fontWeight(.semibold) },
                                icon: { Image(systemName: "folder") }
                            ).font(.subheadline)
                            .padding(12)
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        Button(action: {
                            print("Settings tapped!")
                        }) {
                            Label(
                                title: { Text("Settings").fontWeight(.semibold) },
                                icon: { Image(systemName: "gear") }
                            ).font(.subheadline)
                            .padding(12)
                            .foregroundColor(.white)
                            .background(Color.gray)
                            .cornerRadius(12)
                        }
                    }
                    Divider().padding(.vertical, 2)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 10) {
                        Section(header: HStack {
                                    Text("On Device").font(.title2).fontWeight(.bold)
                                    Spacer()
                            }.padding(.leading, 10)
                        ) {
                            ForEach(viewModel.onDeviceZimFiles, id: \.id) { zimFile in
                                ZimFileCell(zimFile: zimFile)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, calculateHorizontalPadding(size: geometry.size))
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }
    
    private func calculateHorizontalPadding(size: CGSize) -> CGFloat {
        switch size.width {
        case 1000..<CGFloat.infinity:
            return (size.width - size.height) / 2 - 20
        case 400..<1000:
            return 20
        default:
            return 10
        }
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

@available(iOS 14.0, *)
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
        .onAppear {
            let database = try? Realm(configuration: Realm.defaultConfig)
            try? database?.write {
                let zimFile = database?.object(ofType: ZimFile.self, forPrimaryKey: "abcd") ?? {
                    let zimFile = ZimFile(value: ["id": "abcd"])
                    database?.add(zimFile)
                    return zimFile
                }()
                zimFile.state = .onDevice
                zimFile.title = "ZimFile Title"
                zimFile.fileDescription = "Lorem Ipsum is simply dummy text of the printing and typesetting industry."
                zimFile.size.value = 10000000000
                zimFile.articleCount.value = 500000
                zimFile.creationDate = Date()
            }
        }
        .previewDevice(PreviewDevice(rawValue: "iPhone 11"))
    }
}
