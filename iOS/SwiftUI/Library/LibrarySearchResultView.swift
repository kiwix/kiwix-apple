//
//  LibrarySearchResultView.swift
//  Kiwix
//
//  Created by Chris Li on 4/13/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import Defaults
import RealmSwift

@available(iOS 13.0, *)
struct LibrarySearchResultView: View {
    @ObservedResults(
        ZimFile.self,
        configuration: Realm.defaultConfig,
        sortDescriptor: SortDescriptor(keyPath: "creationDate", ascending: false)
    ) private var zimFiles

    var zimFileSelected: (String, String) -> Void = { _, _ in }
    
    var body: some View {
        List {
            ForEach(zimFiles) { zimFile in
                Button(action: { zimFileSelected(zimFile.fileID, zimFile.title) }, label: {
                    ZimFileCell(zimFile)
                })
            }
        }.gesture(DragGesture().onChanged { gesture in
            guard gesture.predictedEndLocation.y < gesture.startLocation.y else { return }
            UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.endEditing(false)
        })
    }
    
    func update(_ searchText: String) {
        // update filter
        var predicates = [NSPredicate(format: "title CONTAINS[cd] %@", searchText)]
        if !Defaults[.libraryLanguageCodes].isEmpty {
            predicates.append(NSPredicate(format: "languageCode IN %@", Defaults[.libraryLanguageCodes]))
        }
        _zimFiles.filter = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        // download favicons
        zimFiles.filter { zimFile in zimFile.faviconData == nil }
            .forEach { FaviconDownloadService.shared.download(zimFile: $0) }
    }
}
