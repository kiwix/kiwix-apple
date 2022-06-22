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
            ZimFilesOpened()
        case .downloads:
            ZimFilesDownloads()
        case .new:
            ZimFilesNew()
        case .categories:
            List(Category.allCases) { category in
                NavigationLink {
                    LibraryContent(topic: LibraryTopic.category(category))
                } label: {
                    HStack {
                        Favicon(category: category).frame(height: 26)
                        Text(category.name)
                    }
                }
            }.listStyle(.plain)
        case .category(let category):
            if #available(iOS 15.0, *), category != .ted, category != .stackExchange, category != .other {
                ZimFilesGrid(category: category)
            } else {
                ZimFilesList(category: category)
            }
        }
    }
}
