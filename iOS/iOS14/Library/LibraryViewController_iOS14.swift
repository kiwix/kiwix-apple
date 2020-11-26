//
//  LibraryViewController_iOS14.swift
//  Kiwix
//
//  Created by Chris Li on 11/23/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
class LibraryViewController_iOS14: UIHostingController<AnyView> {
    convenience init() {
        self.init(rootView: AnyView(EmptyView()))
        let libraryView = LibraryView(dismiss: { [unowned self] in
            self.dismiss(animated: true)
        }).environmentObject(LibraryViewModel())
        rootView = AnyView(libraryView)
        modalPresentationStyle = .overFullScreen
    }
}

@available(iOS 14.0, *)
struct LibraryView: View {
    @EnvironmentObject var libraryViewModel: LibraryViewModel
    var dismiss: (() -> Void)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 10) {
                    Section(header: HStack {
                        Text("On Device").font(.title2).fontWeight(.bold)
                        Spacer()
                    }.padding(.leading, 10)) {
                        ForEach(libraryViewModel.onDevice, id: \.id) { zimFile in
                            ZimFileCell(zimFile) {
//                                sceneViewModel.loadMainPage(zimFile: zimFile)
                            }
                        }
                    }
                }.padding()
            }
            .navigationTitle("Library")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) {
                Button(action: dismiss, label: { Text("Done").fontWeight(.medium) })
            }}
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

@available(iOS 14.0, *)
class LibraryViewModel: ObservableObject {
    @Published var onDevice = [ZimFile]() {
        didSet {
            for zimFile in onDevice {
                print(zimFile.categoryRaw)
                groupIDs.insert(zimFile.groupID)
            }
            print(groupIDs)
        }
    }
    var groupIDs = Set<String>()
    private var onDeviceZimFilesPipeline: AnyCancellable? = nil
    
    init() {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "languageCode == %@ AND NOT (categoryRaw IN %@)", "en", ["ted", "stack_exchange", "other"])
            onDeviceZimFilesPipeline = database.objects(ZimFile.self)
                .filter(predicate)
                .sorted(byKeyPath: "size", ascending: false)
                .collectionPublisher
                .subscribe(on: DispatchQueue.main)
                .freeze()
                .map { Array($0) }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just([]) }
                .assign(to: \.onDevice, on: self)
        } catch { }
    }
    
    deinit {
        onDeviceZimFilesPipeline?.cancel()
    }
}
