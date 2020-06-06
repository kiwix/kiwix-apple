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
    let zimFile: ZimFileData
    
    init(_ zimFile: ZimFileData) {
        self.zimFile = zimFile
    }
    
    var body: some View {
        HStack {
            Image(uiImage: UIImage(data: zimFile.faviconData) ?? #imageLiteral(resourceName: "GenericZimFile"))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32.0, height: 32.0)
            VStack(alignment: .leading) {
                Text(zimFile.title)
                    .font(.body)
                    .lineLimit(1)
                Text(zimFile.detail)
                    .font(.footnote)
//                Text([
//                    zimFile.sizeDescription, zimFile.creationDateDescription, zimFile.articleCountDescription
//                ].compactMap({ $0 }).joined(separator: ", "))
//                    .font(.footnote)
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
    
    var body: some View {
        List {
            if viewModel.recentSearchTexts.count > 0 {
                Section(header: Text("Recent")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.recentSearchTexts, id: \.hash) { searchText in
                                Button(searchText) {
                                    print("buton tapped")
                                }
                                .font(Font.footnote.weight(.medium))
                                .foregroundColor(.white)
                                .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                                .background(Color.blue.opacity(0.9))
                                .cornerRadius(12)
                            }
                        }.padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                    }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }
            Section(header: Text("Files")) {
                ForEach(viewModel.zimFiles, id: \.id) { data in
                    ZimFileView(data).onTapGesture {
                        self.viewModel.toggleZimFileIncludedInSearch(zimFileID: data.id)
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }
}

// MARK: - View Model

@available(iOS 13.0, *)
fileprivate struct ZimFileData {
    var id: String
    @State var title: String
    @State var detail: String
    @State var faviconData: Data
    @State var includedInSearch: Bool
}

@available(iOS 13.0, *)
fileprivate class ViewModel: ObservableObject {
    private let database = try? Realm(configuration: Realm.defaultConfig)
    var t: AnyCancellable?
    init() {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue)
            let zimFiles = database.objects(ZimFile.self).filter(predicate).publisher
            t = zimFiles.map { (results) -> [ZimFileData] in
                results.map({ ZimFileData(id: $0.id, title: $0.title, detail: "test", faviconData: $0.faviconData ?? Data(), includedInSearch: $0.includedInSearch) })
            }.catch { error in
                Just([ZimFileData]())
            }.assign(to: \.zimFiles, on: self)
        } catch {}
        recentSearchTexts = Defaults[.recentSearchTexts]
    }

    @Published private(set) var recentSearchTexts = [String]()
    @Published private(set) var zimFiles = [ZimFileData]()
    
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
    }
}
