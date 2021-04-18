//
//  LibrarySearchResultView.swift
//  Kiwix
//
//  Created by Chris Li on 4/13/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct LibrarySearchResultView: View {
    @ObservedResults(
        ZimFile.self,
        configuration: Realm.defaultConfig,
        sortDescriptor: SortDescriptor(keyPath: "creationDate", ascending: true)
    ) private var zimFiles

    var zimFileSelected: (String, String) -> Void = { _, _ in }
    
    var body: some View {
        HStack {
            if zimFiles.count > 0 {
                List {
                    ForEach(zimFiles) { zimFile in
                        Button(action: { zimFileSelected(zimFile.fileID, zimFile.title) }, label: {
                            ZimFileCell(zimFile)
                        })
                    }
                }
            }
        }
    }
    
    func update(_ searchText: String) {
        _zimFiles.filter = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "title CONTAINS[cd] %@", searchText),
            NSPredicate(format: "languageCode IN %@", UserDefaults.standard.libraryLanguageCodes),
        ])
        zimFiles.forEach { zimFile in
            guard zimFile.faviconData == nil,
                  let urlString = zimFile.faviconURL,
                  let url = URL(string: urlString) else { return }
            LibraryService.shared.downloadFavicon(zimFileID: zimFile.fileID, url: url)
        }
    }
}
