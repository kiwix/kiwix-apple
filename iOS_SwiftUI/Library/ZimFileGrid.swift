//
//  ZimFileGrid.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct ZimFileGrid: View {
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "category == %@", "")
    ) private var zimFiles: FetchedResults<ZimFile>

    let topic: Library.Topic
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: ([GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 12)]),
                alignment: .leading,
                spacing: 12,
                pinnedViews: [.sectionHeaders]
            ) {
                ForEach(zimFiles) { zimFile in
                    Text(zimFile.name)
//                    ZimFileCell(zimFile, prominent: .title).onTapGesture { self.selectedZimFile = zimFile }
                }
            }.padding()
        }
        .navigationTitle(topic.name)
        .onAppear {
            updatePredicate()
        }
    }
    
    private func updatePredicate() {
        var predicates = [NSPredicate]()
        switch topic {
        case .category(let category):
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        default:
            break
        }
        zimFiles.nsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

struct ZimFileGrid_Previews: PreviewProvider {
    static var previews: some View {
        ZimFileGrid(topic: .new)
    }
}
