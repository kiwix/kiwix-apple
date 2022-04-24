//
//  ZimFileGrid.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
struct ZimFileGrid: View {
    @FetchRequest private var zimFiles: FetchedResults<ZimFile>

    let topic: Library.Topic
    
    init(topic: Library.Topic) {
        self.topic = topic
        self._zimFiles = {
            let request = ZimFile.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \ZimFile.name, ascending: true)]
            request.predicate = {
                var predicates = [NSPredicate]()
                switch topic {
                case .category(let category):
                    predicates.append(NSPredicate(format: "category == %@", category.rawValue))
                default:
                    break
                }
                return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }()
            return FetchRequest<ZimFile>(fetchRequest: request)
        }()
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: ([GridItem(.adaptive(minimum: 250, maximum: 350), spacing: 12)]),
                alignment: .leading,
                spacing: 12,
                pinnedViews: [.sectionHeaders]
            ) {
                ForEach(zimFiles) { zimFile in
                    ZimFileCell(zimFile, prominent: .title)
                }
            }.padding()
        }
        .navigationTitle(topic.name)
    }
}

@available(iOS 15.0, *)
struct ZimFileGrid_Previews: PreviewProvider {
    static var previews: some View {
        ZimFileGrid(topic: .new)
    }
}
