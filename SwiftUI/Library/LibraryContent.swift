//
//  LibraryContent.swift
//  Kiwix
//
//  Created by Chris Li on 4/24/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct LibraryContent: View {
    let topic: LibraryTopic
    
    var body: some View {
        switch topic {
        case .opened:
            Text("Show opened zim files")
        case .downloads:
            ZimFilesDownloads()
        case .new:
            ZimFilesNew()
        case .categories:
            List {
                ForEach(Category.allCases.map{ LibraryTopic.category($0) }) { topic in
                    NavigationLink {
                        LibraryContent(topic: topic)
                    } label: {
                        Text(topic.name)
                    }
                }
            }.listStyle(.plain)
        case .category(let category):
            if #available(iOS 15.0, *), category != .ted, category != .stackExchange, category != .other {
                ZimFileGrid(topic: topic)
            } else {
                ZimFileList(category: category)
            }
        }
    }
}
