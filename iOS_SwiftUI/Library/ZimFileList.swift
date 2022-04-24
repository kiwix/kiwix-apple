//
//  ZimFileList.swift
//  Kiwix
//
//  Created by Chris Li on 4/24/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct ZimFileList: View {
    @FetchRequest private var zimFiles: FetchedResults<ZimFile>
    
    let topic: Library.Topic
    
    init(topic: Library.Topic) {
        self.topic = topic
        self._zimFiles = {
            let request = ZimFile.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \ZimFile.name, ascending: true)]
            request.predicate = topic.predicate
            return FetchRequest<ZimFile>(fetchRequest: request)
        }()
    }
    
    var body: some View {
        List(zimFiles) { zimFile in
            NavigationLink {
                Text("Detail about zim file: \(zimFile.name)")
            } label: {
                Text(zimFile.name)
            }
        }
        .navigationTitle(topic.name)
        .listStyle(.plain)
    }
}

//struct ZimFileList_Previews: PreviewProvider {
//    static var previews: some View {
//        ZimFileList(zimFiles: .constant(FetchedResults<ZimFile>))
//    }
//}
