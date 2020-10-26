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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var sceneViewModel: SceneViewModel
    @EnvironmentObject var zimFilesViewModel: ZimFilesViewModel
    
    var libraryButtonTapped: (() -> Void)?
    var settingsButtonTapped: (() -> Void)?
    
    var body: some View {
        LazyVStack {
            HStack {
                Image("Kiwix")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(2)
                    .frame(idealHeight: 10)
                    .foregroundColor(.black)
                    .background(Color(.white).opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
            Divider().padding(.vertical, 2)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 10) {
                Section(header: HStack {
                    Text("On Device").font(.title2).fontWeight(.bold)
                    Spacer()
                }.padding(.leading, 10)) {
                    ForEach(zimFilesViewModel.onDeviceZimFiles, id: \.id) { zimFile in
                        ZimFileCell(zimFile) {
                            sceneViewModel.loadMainPage(zimFile: zimFile)
                        }
                    }
                }
            }
        }
        .modifier(ScrollableModifier())
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
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
