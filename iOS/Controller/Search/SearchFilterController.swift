//
//  SearchFilterController.swift
//  Kiwix
//
//  Created by Chris Li on 6/6/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import UIKit
import Defaults
import RealmSwift

@available(iOS 13.0, *)
fileprivate struct ZimFileView: View {
    let zimFile: ZimFile
    
    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .frame(width: 36.0, height: 36.0)
                    .foregroundColor(Color.white.opacity(0.2))
                Image(uiImage: UIImage(data: zimFile.faviconData ?? Data()) ?? #imageLiteral(resourceName: "GenericZimFile"))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32.0, height: 32.0)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            VStack(alignment: .leading) {
                Text(zimFile.title)
                    .font(.body)
                    .lineLimit(1)
                Text(zimFile.description)
                    .font(.footnote)
            }
            Spacer()
            if zimFile.includedInSearch {
                Image(systemName: "checkmark")
                    .foregroundColor(Color.blue.opacity(0.9))
                    .font(Font.system(.body).bold())
            }
        }
    }
}

@available(iOS 13.0, *)
struct SearchFilterView: View {
    @ObservedObject private var viewModel = ViewModel()
    var recentSearchButtonAction: ((String) -> Void)?
    
    var body: some View {
        List {
            if viewModel.recentSearchTexts.count > 0 {
                Section(header: Text("Recent")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.recentSearchTexts, id: \.hash) { searchText in
                                Button(searchText) {
                                    self.recentSearchButtonAction?(searchText)
                                }
                                .font(Font.footnote.weight(.medium))
                                .foregroundColor(.white)
                                .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                                .background(Color.blue.opacity(0.85))
                                .cornerRadius(.infinity)
                            }
                        }.padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                    }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }
            Section(header: Text("Files")) {
                ForEach(viewModel.zimFiles, id: \.id) { zimFile in
                    ZimFileView(zimFile: zimFile)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.viewModel.toggleZimFileIncludedInSearch(zimFileID: zimFile.id)
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }
}

// MARK: - View Model

@available(iOS 13.0, *)
fileprivate class ViewModel: ObservableObject {
    private let database = try? Realm(configuration: Realm.defaultConfig)
    @Published private(set) var recentSearchTexts = [String]()
    @Published private(set) var zimFiles = [ZimFile]()
    
    var zimFilesCancellable: AnyCancellable?
    
    init() {
        let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue)
        zimFilesCancellable = database?.objects(ZimFile.self)
            .filter(predicate)
            .publisher
            .map { results -> [ZimFile] in
                results.map({ $0 })
            }.catch { error in
                Just([ZimFile]())
            }.assign(to: \.zimFiles, on: self)
        recentSearchTexts = Defaults[.recentSearchTexts]
    }
    
    func toggleZimFileIncludedInSearch(zimFileID: String) {
        guard let zimFile = database?.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else { return }
        try? database?.write {
            zimFile.includedInSearch = !zimFile.includedInSearch
        }
    }
}

// MARK: - UIHostingController

@available(iOS 13.0, *)
class SearchFilterController: UIHostingController<SearchFilterView> {
    convenience init() {
        self.init(rootView: SearchFilterView())
        rootView.recentSearchButtonAction = { [unowned self] searchText in
            guard let controller = self.presentingViewController as? ContentController else { return }
            controller.searchController.searchBar.text = searchText
        }
    }
}
